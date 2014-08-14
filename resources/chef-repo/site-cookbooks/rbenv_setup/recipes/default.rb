#
# Cookbook Name:: rbenv_setup
# Recipe:: default
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe "rbenv::default"
include_recipe "rbenv::ruby_build"

rbenv_ruby node['rbenv_setup']['ruby_version'] do
  ruby_version node['rbenv_setup']['ruby_version']
  global node['rbenv_setup']['global']
end

rbenv_gem "bundler" do
  ruby_version node['rbenv_setup']['ruby_version']
end
