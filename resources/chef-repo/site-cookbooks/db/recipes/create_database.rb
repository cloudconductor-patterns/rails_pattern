#
# Cookbook Name:: db
# Recipe:: create_database
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "database::mysql"

mysql_connection_info = {
  :host     => node['create_user']['host'],
  :username => node['create_user']['username'],
  :password => node['create_user']['pass']
}


mysql_database node['create_user']['database_name'] do
  connection mysql_connection_info
  encoding node['create_database']['encoding']
  action :create
end

mysql_database 'flush the privileges' do
  connection mysql_conneciton_info
  sql        'flush privileges'
  action     :query
end

