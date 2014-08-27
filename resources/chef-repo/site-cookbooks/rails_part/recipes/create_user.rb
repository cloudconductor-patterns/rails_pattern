#
# Cookbook Name:: rails_part
# Recipe:: create_user
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

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
