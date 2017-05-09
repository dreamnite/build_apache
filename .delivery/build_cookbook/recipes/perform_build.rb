#
# Cookbook:: build_cookbook
# Recipe:: perform_build.rb
#
# Copyright:: 2017, Jp Robinson, All Rights Reserved.

include_recipe 'build_cookbook::setup_build' ## Just to be sure we don't accidently forget to include the setup phase
## Steps to actually build/compile apache
build_config = ab_load_config(node['apache_build']['config_file']) # Load and parse the config file
dev_null = '>/dev/null' if build_config['less_output']
src_dir = "#{workflow_workspace_repo}/httpd" # Root source directory
bash 'Clean up old builds if needed' do
  code "make clean #{dev_null}"
  only_if { File.exist? "#{src_dir}/Makefile" }
  cwd src_dir
end
bash "Running configure with options: #{build_config['configure_options'].join(', ')}" do
  code "#{src_dir}/configure #{build_config['configure_options'].map { |opt| "--#{opt}" }.join ' '} #{dev_null}"
  cwd src_dir
end

bash 'Running Make' do
  code 'make #{dev_null}'
  cwd src_dir
end
