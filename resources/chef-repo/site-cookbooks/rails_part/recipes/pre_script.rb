#
# Cookbook Name:: rails_part
# Recipe:: pre_script
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
bash "pre_script" do
  action :run
  code "#{node['rails_part']['pre_script']}"
end
