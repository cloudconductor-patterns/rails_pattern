#
# Cookbook Name:: nginx_part
# Recipe:: deploy
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

if node['nginx_part']['maintenance']
  file "/usr/share/nginx/html/index.html" do
    owner "root"
    group "root"
    content node['nginx_part']['maintenance']
    action :create
  end

  file "/etc/nginx/conf.d/default.conf" do
    action :delete
  end

  template "/etc/nginx/conf.d/default.conf" do
    action :create
    source 'default.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end

  service "nginx" do
    action :restart
  end
end
