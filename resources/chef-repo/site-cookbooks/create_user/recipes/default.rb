#
# Cookbook Name:: create_user
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

user node['create_user']['user'] do
  password node['create_user']['passwd']
  supports :manage_home => node['create_user']['manage_home']
  action :create
end

group node['create_user']['group'] do
  action :create
  members [node['create_user']['user']]
  append true
end
