#
# Cookbook:: build_cookbook
# Recipe:: perform_build.rb
#
# Copyright:: 2017, Jp Robinson .
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


include_recipe 'build_cookbook::setup_build' ## Just to be sure we don't accidently forget to include the setup phase
## Steps to actually build/compile apache
build_config = ab_load_config(node['apache_build']['config_file']) # Load and parse the config file
dev_null = '2>&1>/dev/null' if build_config['less_output']
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
  code "make #{dev_null}"
  cwd src_dir
end
