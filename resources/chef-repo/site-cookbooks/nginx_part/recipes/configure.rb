#
# Cookbook Name:: nginx_part
# Recipe:: deploy
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

file "/usr/share/nginx/html/index.html" do
  action :delete
end

file "/usr/share/nginx/html/index.html" do
  owner "root"
  group "root"
  content node['maintenance']
  action :create
end
