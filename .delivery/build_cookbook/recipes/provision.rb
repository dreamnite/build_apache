#
# Cookbook:: build_cookbook
# Recipe:: provision
#
# Copyright:: 2017, Jp Robinson, All Rights Reserved.
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
      package_url = "http://#{publish_info['host']}/custom-httpd-#{build_config['build_number']}.tar.gz"
        env_name = if node['delivery']['change']['stage'] == 'acceptance'
                    get_acceptance_environment
                  else 
                    node['delivery']['change']['stage'] == 'acceptance'
                  end
        
        cur_env = ::DeliveryTruck::Helpers::Provision.fetch_or_create_environment(env_name) # Helper method from delivery-truck's provision stage
        cur_env.default_attributes['apache_build']['package_url'] = package_url
        cur_env.save
      end # unless
    end # with_server_config
  end # block do
end # ruby block