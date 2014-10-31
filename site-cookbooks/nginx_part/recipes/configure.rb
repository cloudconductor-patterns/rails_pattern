#
# Cookbook Name:: nginx_part
# Recipe:: deploy
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

if node['nginx_part']['maintenance']
  directory "#{node['nginx']['default_root']}/maintenance" do
    action :create
    owner 'root'
    group 'root'
    recursive true
  end

  file "#{node['nginx']['default_root']}/maintenance/index.html" do
    action :create
    owner 'root'
    group 'root'
    content node['nginx_part']['maintenance']
  end

  file "#{node['nginx']['dir']}/conf.d/default.conf" do
    action :delete
  end

  template "#{node['nginx']['dir']}/conf.d/default.conf" do
    action :create
    source 'default.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables(
      maintenance_dir: "#{node['nginx']['default_root']}/maintenance"
    )
  end

  service 'nginx' do
    action :reload
    supports reload: true
  end
end
