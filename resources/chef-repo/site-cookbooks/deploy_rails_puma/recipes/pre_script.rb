#
# Cookbook Name:: deploy_rails_puma
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
bash "pre_script" do
  action :run
  code "#{node['deploy_rails_puma']['pre_script']}"
end
