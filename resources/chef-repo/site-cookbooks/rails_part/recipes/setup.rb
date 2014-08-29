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
include_recipe 'rails_part::create_user'
