#
# Cookbook Name:: mysql_part
# Recipe:: setup
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe 'mysql'
include_recipe 'mysql_part::create_user'
include_recipe 'mysql_part::create_database'
