#
# Cookbook Name:: mysql_cookbook
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

mysql_connection_info = {
  :host     => node['mysql']['hostname'],
  :username => node['mysql']['user'],
  :password => node['mysql']['server_root_password']
}

include_recipe "database::mysql"

mysql_database "delete_unknown_user" do
  connection mysql_connection_info
  sql        "DELETE from mysql.user where User = ''"
  action     :query
end

mysql_database "flush privilages" do
  connection mysql_connection_info
  sql        "flush privilages"
  action     :query
end


