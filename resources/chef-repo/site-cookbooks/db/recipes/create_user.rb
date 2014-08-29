#
# Cookbook Name:: db
# Recipe:: create_user
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'database::mysql'

# create connection info
mysql_connection_info = {
  host:     node['create_user']['host'],
  username: node['create_user']['username'],
  password: node['create_database']['pass']
}

# create user
mysql_database_user node['create_user']['new_username'] do
  connection mysql_connection_info
  password node['create_user']['new_password']
  action :create
end

# Grant db
mysql_database_user node['create_user']['new_username'] do
  connection mysql_connection_info
  password node['create_user']['new_password']
  database_name node['create_user']['database_name']
  host node['create_user']['host']
  privileges node['create_user']['privileges']
  require_ssl node['create_user']['require_ssl']
  action :grant
end
