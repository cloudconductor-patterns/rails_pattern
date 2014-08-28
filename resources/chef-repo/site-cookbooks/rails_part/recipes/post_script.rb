#
# Cookbook Name:: rails_part
# Recipe:: post_script
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
bash "post_script" do
  action :run
  code "#{node['deploy_rails_puma']['post_script']}"
end
