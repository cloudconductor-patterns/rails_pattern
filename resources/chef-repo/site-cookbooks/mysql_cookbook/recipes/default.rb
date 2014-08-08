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

mysql_database "change_pass" do
  connection mysql_connection_info
  sql        "UPDATE mysql.user SET Password = #{node['mysql']['new_root_password']} where User = #{node['mysql']['server_root_password']}"
  action     :query
end

mysql_database "flush privilages" do
  connection mysql_connection_info
  sql        "flush privilages"
  action     :query
end


