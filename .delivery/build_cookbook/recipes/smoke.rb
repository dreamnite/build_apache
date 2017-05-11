#
# Cookbook:: build_cookbook
# Recipe:: smoke
#
# Copyright:: 2017, Jp Robinson, All Rights Reserved.

build_root = "#{workflow_workspace_repo}/build"

template '#{workflow_workspace_repo}/min_httpd_conf.conf' do
  source 'min_httpd_conf.erb'
  variables(server_root: build_root)
end

execute 'Start apache locally' do
  command "#{build_root}/bin/httpd -k start -f #{workflow_workspace_repo}/min_httpd_conf.conf"
end

http_request 'test_request' do
  url 'http://localhost:12345/'
end

execute 'Stop apache locally' do
  command "#{build_root}/bin/httpd -k stop -f #{workflow_workspace_repo}/min_httpd_conf.conf"
end
