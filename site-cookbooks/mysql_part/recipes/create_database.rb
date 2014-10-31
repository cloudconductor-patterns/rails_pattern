#
# Cookbook Name:: mysql_part
# Recipe:: create_database
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'database::mysql'

mysql_connection_info = {
  host:     '127.0.0.1',
  username: 'root',
  password: node['mysql']['server_root_password']
}

mysql_database node['mysql_part']['app']['database'] do
  connection mysql_connection_info
  encoding node['mysql_part']['app']['encoding']
  action :create
end

# create database user
mysql_database_user 'create database user' do
  username node['mysql_part']['app']['username']
  connection mysql_connection_info
  password node['mysql_part']['app']['password']
  action :create
end

# Grant database
mysql_database_user 'Grant database' do
  username node['mysql_part']['app']['username']
  connection mysql_connection_info
  database_name node['mysql_part']['app']['database']
  host '%'
  privileges node['mysql_part']['app']['privileges']
  require_ssl node['mysql_part']['app']['require_ssl']
  action :grant
end

mysql_database 'flush the privileges' do
  connection mysql_connection_info
  sql 'flush privileges'
  action :query
end
