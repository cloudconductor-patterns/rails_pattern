#
# Cookbook Name:: rails_part
# Recipe:: rbenv_setup
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'rbenv::default'
include_recipe 'rbenv::ruby_build'

rbenv_ruby node['rails_part']['ruby']['version'] do
  ruby_version node['rails_part']['ruby']['version']
  global node['rails_part']['ruby']['global']
end

rbenv_gem 'bundler' do
  ruby_version node['rails_part']['ruby']['version']
end
