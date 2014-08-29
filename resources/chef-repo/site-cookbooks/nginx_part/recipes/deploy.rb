#
# Cookbook Name:: nginx_part
# Recipe:: deploy
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
file '/etc/nginx/conf.d/default.conf' do
  action :delete
end

link '/etc/nginx/sites-enabled/000-default' do
  link_type :symbolic
  action :delete
end

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

git "#{node['nginx_part']['static_root']}/#{node['nginx_part']['app_name']}" do
  repository node['cloudconductor']['application_url']
  revision node['cloudconductor']['application_revision']
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
  notifies :restart, 'service[nginx]'
end

service 'nginx' do
  action :nothing
  supports restart: true, reload: true, status: true
end
