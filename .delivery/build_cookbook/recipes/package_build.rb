#
# Cookbook:: build_cookbook
# Recipe:: package_build
#
# Copyright:: 2017, Jp Robinson, All Rights Reserved.

include_recipe 'build_cookbook::perform_build' # Make sure prereqs are done
with_server_config do # Chef server context, so we can get the databag.
  begin
    publish_info = data_bag_item('build_apache', 'publish_info')
  rescue
    Chef::Log.warn 'Unable to get data bag, not able to publish'
    publish_info = {}
  end

  # Steps to package up what is produced by the build
  build_config = ab_load_config(node['apache_build']['config_file']) # Load and parse the config file
  build_file = "custom-httpd-#{build_config['build_number']}.tar.gz"
  src_dir = "#{workflow_workspace_repo}/httpd" # Root source directory
  build_root = "#{workflow_workspace_repo}/build"
  # Clean the build dir just to make sure we are doing this cleanly
  bash 'Cleaning build directory' do
    code "rm -rf #{build_root}"
  end
  bash 'Running Make' do
    code "make DESTDIR=#{build_root} install"
    cwd src_dir
  end

  bash 'Packaging build' do
    code "tar cvzf #{workflow_workspace_repo}/#{build_file} *"
    cwd build_root
  end

  ## Publish the tar file
  unless publish_info.empty?
    file "#{workflow_workspace_repo}/ssh_key" do
      content publish_info['key']
      mode '0700'
    end

    sudo = 'sudo' if publish_info['sudo']
    bash 'Publishing tar file' do
      code <<-EOH
        scp -o StrictHostKeyChecking=no -i #{workflow_workspace_repo}/ssh_key #{workflow_workspace_repo}/#{build_file} #{publish_info['user']}@#{publish_info['host']}:~/
        ssh -o StrictHostKeyChecking=no -i #{workflow_workspace_repo}/ssh_key #{publish_info['user']}@#{publish_info['host']} "#{sudo} mv ~/#{build_file} #{publish_info['dir']}/"
        EOH
      action :run
    end
  end
end
