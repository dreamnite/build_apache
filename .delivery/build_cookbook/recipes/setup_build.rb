#
# Cookbook:: build_cookbook
# Recipe:: set_up_build
#
# Copyright:: 2017, Jp Robinson, All Rights Reserved.

# Steps to set up a build of the correct apache version
build_config = ab_load_config("#{workflow_workspace_repo}/#{node['apache_build']['config_file']}") # Load and parse the config file

build_config['required_build_packages'].each do |cur_package|
  package cur_package # Install packages required to make the build run
end

src_dir = "#{workflow_workspace_repo}/httpd" # Root directory for the source to go into on the build node

# Check out source code from git
git src_dir do
  repository build_config['apache_source']
  revision build_config['apache_version']
end

git "#{src_dir}/srclib/apr" do
  repository build_config['apr_source']
  revision build_config['apr_version']
end
git "#{src_dir}/srclib/apr-util" do
  repository build_config['apr_utils_source']
  revision build_config['apr_utils_version']
end

bash 'Building autoconf script' do
  code "#{src_dir}/buildconf"
end
