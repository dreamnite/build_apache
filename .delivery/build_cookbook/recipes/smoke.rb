#
# Cookbook:: build_cookbook
# Recipe:: smoke
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


with_server_config do
  # retrieve what we set in provision
  env_name = if node['delivery']['change']['stage'] == 'acceptance'
               get_acceptance_environment
             else
               node['delivery']['change']['stage']
             end

  cur_env = ::DeliveryTruck::Helpers::Provision.fetch_or_create_environment(env_name) # Helper method from delivery-truck's provision stage

  build_root = "#{workflow_workspace_repo}/smoke_test"

  directory build_root do
    action :create
  end
  remote_file "#{build_root}/custom-apache.tgz" do
    source cur_env.default_attributes['custom-apache']['url']
    action :create
  end
  bash 'Extract Tar File' do
    code "tar xzf #{build_root}/custom-apache.tgz"
    cwd build_root
    action :run
  end

  template "#{workflow_workspace_repo}/min_httpd_conf.conf" do
    source 'min_httpd_conf.erb'
    variables(server_root: "#{build_root}/opt/apache")
  end

  execute 'Start apache locally' do
    command "#{build_root}/opt/apache/bin/httpd -k start -f #{workflow_workspace_repo}/min_httpd_conf.conf"
    environment 'LD_LIBRARY_PATH' => "#{build_root}/opt/apache/lib"
  end

  http_request 'test_request' do
    url 'http://localhost:12345/'
  end

  execute 'Stop apache locally' do
    command "#{build_root}/opt/apache/bin/httpd -k stop -f #{workflow_workspace_repo}/min_httpd_conf.conf"
    environment 'LD_LIBRARY_PATH' => "#{build_root}/opt/apache/lib"
  end
end # with_server_config
