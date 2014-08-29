#
# Cookbook Name:: mysql_part
# Recipe:: create_user
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'database::mysql'

# create connection info
mysql_connection_info = {
  host:     node['mysql_part']['host'],
  username: node['mysql_part']['username'],
  password: node['mysql_part']['password']
}

# create user
mysql_database_user node['mysql_part']['new_username'] do
  connection mysql_connection_info
  password node['mysql_part']['new_password']
  action :create
end

# Grant database
mysql_database_user node['mysql_part']['new_username'] do
  connection mysql_connection_info
  password node['mysql_part']['new_password']
  database_name node['mysql_part']['database_name']
  host node['mysql_part']['host']
  privileges node['mysql_part']['privileges']
  require_ssl node['mysql_part']['require_ssl']
  action :grant
end
