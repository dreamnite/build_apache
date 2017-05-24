#
# Cookbook:: build_cookbook
# Recipe:: provision
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

ruby_block 'Set Package URL for current environment' do
  block do
    with_server_config do
      build_config = ab_load_config(node['apache_build']['config_file'])
      begin
        publish_info = data_bag_item('build_apache', 'publish_info')
      rescue
        publish_info = nil
      end
      unless publish_info.nil?
        package_url = "http://#{publish_info['host']}/#{publish_info['dir'].gsub(publish_info['docroot'], '')}/custom-httpd-#{build_config['build_number']}.tar.gz"
        env_name = if node['delivery']['change']['stage'] == 'acceptance'
                     get_acceptance_environment
                   else
                     node['delivery']['change']['stage']
                   end

        cur_env = ::DeliveryTruck::Helpers::Provision.fetch_or_create_environment(env_name) # Helper method from delivery-truck's provision stage
        cur_env.default_attributes['custom-apache'] = {} if cur_env.default_attributes['custom-apache'].nil? # Init top level, if not already present
        cur_env.default_attributes['custom-apache']['url'] = package_url
        cur_env.default_attributes['custom-apache']['docroot'] = publish_info['docroot']
        cur_env.default_attributes['custom-apache']['build_number'] = build_config['build_number']
        cur_env.save
      end # unless
    end # with_server_config
  end # block do
end # ruby block
