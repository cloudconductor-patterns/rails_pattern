#
# Cookbook Name:: web_deploy
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
directory node['web_deploy']['default_root'] do
  owner "root"
  group "root"
  mode 00775
  recursive true
  not_if {Dir.exists?(node['web_deploy']['default_root'])}
  action :create
end

package "git" do
  action :install
end

git node['web_deploy']['app_path'] do
  repository node['web_deploy']['repository']
  action :sync
  revision node['web_deploy']['version']
  not_if {Dir.exists?(node['web_deploy']['app_path'])}
end

directory node['nginx_app']['log'] do
  owner "root"
  group "root"
  recursive true
  not_if {Dir.exists?(node['nginx_app']['log'])}
  action :create
end

template "#{node['web_deploy']['app_conf_path']}/#{node['web_deploy']['app_conf_name']}" do
  source 'app.conf.erb'
  mode '0644'
  action :create
end

service "nginx" do
  action :restart
end
