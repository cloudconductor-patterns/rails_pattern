#
# Cookbook Name:: nginx_part
# Recipe:: deploy
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
directory node['nginx_part']['static_root'] do
  owner node['nginx_part']['static_owner']
  group node['nginx_part']['static_group']
  mode node['nginx_part']['static_mode']
  recursive true
  action :create
end

package 'git' do
  action :install
end

git node['nginx_part']['app_path'] do
  repository node['nginx_part']['app_repository']
  revision node['nginx_part']['app_revision']
  action :sync
end

directory node['nginx_part']['app_log_dir'] do
  owner node['nginx_part']['log_owner']
  group node['nginx_part']['log_group']
  mode node['nginx_part']['log_mode']
  recursive true
  action :create
end

template \
  "#{ \
    node['nginx_part']['app_conf_path'] \
  }/#{ \
    node['nginx_part']['app_conf_name'] \
  }" do
  source 'app.conf.erb'
  mode '0644'
  action :create
end

service 'nginx' do
  action :restart
end
