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
  host:     node['mysql_part']['host'],
  username: node['mysql_part']['username'],
  password: node['mysql_part']['passwprd']
}

mysql_database node['mysql_part']['database_name'] do
  connection mysql_connection_info
  encoding node['mysql_part']['encoding']
  action :create
end

mysql_database 'flush the privileges' do
  connection mysql_conneciton_info
  sql 'flush privileges'
  action :query
end
