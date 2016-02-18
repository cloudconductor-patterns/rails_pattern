#
# Cookbook Name:: nginx_part
# Recipe:: setup
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
yum_package 'openssl'
include_recipe 'nginx'
