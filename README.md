# build_apache

Chef Workflow project to build and package a custom apache build for distribution.
This was put together as part of a demo presented at ChefConf 2017, "Beyond the Cookbook: Using Chef Workflow to Bring
Continuous Delivery to Any Project". 

The project is fairly demo specific, for example: in a real world project, you would probably store the source code you are building within the project itself rather than pulling from a separate git repo, although the code to do so could still be useful for dependencies like apr, where the build expects to find it in a specific subdirectory.

## Contact

If you have any questions or issues, feel free to contact me here on github, or find me on the chef-community slack as @dreamnite.

## Project set up

If you wish to add the project to your delivery server to try locally, you can clone it locally and use `delivery init` to do so. It expects the following to be set up to function:

### Databag configuration

A databag `build_apache` needs to exist with an item called `publish_info`. The format is as follows:
```
{
  "user": "my-ssh-user",
  "host": "webserver_to_publish_to",
  "docroot": "/var/www/html",
  "dir": "/var/www/html/packages",
  "key": "-----BEGIN RSA PRIVATE KEY-----\nNOTAREALKEY\n-----END RSA PRIVATE KEY-----\n",
  "sudo": true,
  "id": "publish_info"
}
```

Where:

* `user` is the user we use to ssh while publishing or performing the functional test
* `host` is the host we want to publish to
* `docroot` will be set as the docroot directory for the custom_apache companion cookbook
* `dir` is the directory on `host` we will publish to
* `key` is the RSA public key for both the publish nodes and any we will run functional tests against. Note that JSON does not support multiline strings, so the line endings must be escaped as `\n`. This can be accomplished by `cat ~/public_key.pem |sed 's/$/\\n/'|tr -d \\n`.
* `sudo` set to true if we are using a non-root user (highly recommended!)

### Build node sudo permissions

Because this installs pre-requisite packages, the build user (dbuild by default) needs to be able to run yum via sudo. This can be accomplished by adding a file to /etc/sudoers.d with the following line on each of your build nodes:
```
dbuild ALL=(root) NOPASSWD:/bin/yum
```

## Recipe Overview

This build cookbook uses the following recipes:

* Pre-Merge
  * Unit - Does a test-compile, see Build Specific recipes below
  * Lint - Checks the configuration file for errors
* Post-Merge
  * Repeat Unit and Lint 
  * Publish - Does a full compile, creates a package, and publishes it to the web server specified in the build_apache data bag.
* Deployment
  * Provision - Sets up node attributes for use with the custom_apache companion cookbook.
  * Smoke - Deploys the current version of the published package on the build node and starts it with a minimal config to test operation.
  * Functional - Runs chef client on nodes running the custom_apache cookbook in the appropriate environment and confirms basic operation.
* Build Specific
  * setup_build - Checks out the code for apache, and makes it ready for the build.
  * perform_build - Runs the actual build (`./configure; make`)
  * package_build - Installs the build (`make install`), creates a tar package and publishes it to the web server specified in the `publish_info`

## Deeper Dive

### Unit

Performs a basic build by calling in `setup_build` and `perform_build` recipes

#### Setup_Build

Installs required packages for the build, checks out the source code for apache and it's apr requirements from git, and prepares it for building.

Useful/interesting sections in this recipe:

It is worth noting that the package install is not accomplished with a package resource, as the cookbook is not running as a privledged user, and therefore must instead use an execute resource with `sudo` to run `yum`. 

Also, the `workflow_workspace_repo` helper from delivery-sugar. The delivery-sugar cookbook provides many helpers to make developing a build cookbook easier, see [The delivery-sugar README](https://github.com/chef-cookbooks/delivery-sugar/#dsl) for more information.

#### Perform_Build

This section could be used for most things that follow the typical `make clean; ./configure <options>; make` model to build.  Notice that it uses simple bash resources started in the source directory to run the build:
```ruby 
bash 'Running Make' do
  code "make #{dev_null}"
  cwd src_dir
end
```
While these could be combined into a single bash resource to run all three phases, keeping the individual phases separate will help catch and isolate errors, should any occur, within the build process.

### Lint

Checks over the build_config.json file and validates it within a ruby block. Also checks to make sure the build number has been updated from the last delivered change.

Useful/interesting sections in this recipe:
```ruby
with_server_config do
    cur_env = ::DeliveryTruck::Helpers::Provision.fetch_or_create_environment('delivered')
      unless cur_env.default_attributes['custom-apache'].nil?
        raise 'Build number needs an update' if cur_env.default_attributes['custom-apache']['build_number'] == parsed_conf['build_number']
      end
```

The above code uses the `with_server_config` helper from delivery-sugar to contact the chef server configured for use with workflow, and the `fetch_or_create_environment` helper from delivery-truck to retrieve the delivered environment to compare the build number and see if has been updated. These two helpers are very useful for any time you need to update an environment on your chef server, such as when publishing information.

### Publish

Performs a full build again. Notice that we can't just use the state from the end of `unit`, as even if the phases happen to run on the same build node, they are checked out with clean slate into different directories. In simpler terms: Phases do not remember state.

At the end of the build it calls an additonal step: `package_build` to package and publish the build.

#### Package_Build

Package build installs and builds a package of the build, and then uses the information in the build_apache data bag to publish it.

Items of note:
It again uses `with_server_config` to retrieve the data_bag, using same functions to do so as in a normal cookbook:
```
with_server_config do # Chef server context, so we can get the databag.
  begin
    publish_info = data_bag_item('build_apache', 'publish_info')
  rescue
    Chef::Log.warn 'Unable to get data bag, not able to publish'
    publish_info = {}
  end
  ```
It is also worth noting that the scp/ssh commands to publish the tar file use the `StrictHostKeyChecking=no` option to avoid hangs/failures as the host will be unknown on first run for each build node.

### Provision 

Provision sets several attributes used by custom-apache during deployment. 
```ruby
cur_env = ::DeliveryTruck::Helpers::Provision.fetch_or_create_environment(env_name) # Helper method from delivery-truck's provision stage
cur_env.default_attributes['custom-apache'] = {} if cur_env.default_attributes['custom-apache'].nil? # Init top level, if not already present
cur_env.default_attributes['custom-apache']['url'] = package_url
cur_env.default_attributes['custom-apache']['docroot'] = publish_info['docroot']
cur_env.default_attributes['custom-apache']['build_number'] = build_config['build_number']
cur_env.save
```

Again, we use `fetch_or_create_environment` to retrieve the environment, and then interact with the `default_attributes` to set them appropriately. Finally, we use the `save` function of the envrionment to upload the changed items back to the chef server.

### Smoke

Downloads and extracts the packge, sets up a basic configuration file and then uses `http_request` to test operation. Notice that all of these are standard chef resources.

Also, while this test is useful for the demo, it's generally suggested that the build nodes NOT be used for running the test on (ie: deploying the artifacts locally), to avoid anything which may break the ability of the pipeline to deploy further changes.

### Functional

Functional seaches for nodes in the appropriate environment running an appropriate recipe and deploys the new package using chef-client.

This recipe could be easily adjusted to replace the standard `deploy` phase from delivery-truck to use ssh instead of push jobs, but you will need a shared key. 

Parts to note would be how the search query is set up:
```ruby
search_query = "recipe:custom_apache* AND chef_environment:#{delivery_environment}"
  my_nodes = search(:node, search_query)
```
The syntax is the same as what you would pass to knife search, or use with knife ssh, as we do later in that recipe:
```ruby
execute 'Run Chef Client' do
      command "knife ssh -c #{workflow_workspace}/.chef/knife.rb '#{search_query}' 'sudo chef-client' -a ipaddress -x ec2-user -i #{workflow_workspace_repo}/ssh_key"
      action :run
      not_if { my_nodes.empty? }
    end
```














 




