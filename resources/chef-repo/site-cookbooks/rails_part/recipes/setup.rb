#
# Cookbook Name:: rails_part
# Recipe:: setup
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "git"
include_recipe "build-essential::_#{node['platform_family']}"

package 'mysql-devel' do
  action :install
end

package 'sqlite-devel' do
  action :install
end

include_recipe 'rails_part::rbenv_setup'
include_recipe 'iptables::disabled'

user node['rails_part']['user']['name'] do
  password node['rails_part']['user']['passwd']
  supports manage_home: node['rails_part']['user']['manage_home']
  action :create
end

group node['rails_part']['user']['group'] do
  action :create
  members [node['rails_part']['user']['name']]
  append true
end
