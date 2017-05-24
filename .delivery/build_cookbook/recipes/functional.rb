#
# Cookbook:: build_cookbook
# Recipe:: functional
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

with_server_config do # Chef server context, so we can get the databag.
  begin
    publish_info = data_bag_item('build_apache', 'publish_info')
  rescue
    Chef::Log.warn 'Unable to get data bag, not able to publish'
    publish_info = {}
  end
  search_query = "recipe:custom_apache* AND chef_environment:#{delivery_environment}"
  my_nodes = search(:node, search_query)
  my_nodes.map!(&:name)
  unless publish_info.empty?
    file "#{workflow_workspace_repo}/ssh_key" do
      content publish_info['key']
      mode '0700'
      sensitive true
    end
    execute 'Run Chef Client' do
      command "knife ssh -c #{workflow_workspace}/.chef/knife.rb '#{search_query}' 'sudo chef-client' -a ipaddress -x ec2-user -i #{workflow_workspace_repo}/ssh_key"
      action :run
      not_if { my_nodes.empty? }
    end
    my_nodes.each do |cur_node|
      http_request 'Test Request' do
        url "http://#{cur_node}:8080/"
        action :get
      end
    end # my_nodes.each
  end # unless publish_info
end # with_server_config
