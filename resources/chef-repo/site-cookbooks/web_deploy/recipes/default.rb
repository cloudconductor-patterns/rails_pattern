#
# Cookbook Name:: web_deploy
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
directory node['web_deploy']['default_root'] do
  owner node['web_deploy']['owner']
  group node['web_deploy']['group']
  mode node['web_deploy']['mode']
  recursive true
  action :create
end

package 'git' do
  action :install
end

git node['web_deploy']['app_path'] do
  repository node['web_deploy']['repository']
  revision node['web_deploy']['revision']
  action :sync
end

directory node['nginx_app']['log'] do
  owner node['nginx_log']['owner']
  group node['nginx_log']['group']
  mode node['nginx_log']['mode']
  recursive true
  action :create
end

template \
  "#{ \
    node['web_deploy']['app_conf_path'] \
  }/#{ \
    node['web_deploy']['app_conf_name'] \
  }" do
  source 'app.conf.erb'
  mode '0644'
  action :create
end

service 'nginx' do
  action :restart
end
