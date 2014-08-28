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
  code "#{node['deploy_rails_puma']['pre_script']}"
end
