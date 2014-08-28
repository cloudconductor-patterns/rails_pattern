#
# Cookbook Name:: rails_part
# Recipe:: deploy_rails_puma
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
include_recipe "git"
include_recipe "build-essential::_#{node['platform_family']}"

db_params = node['deploy_rails_puma']['db']

include_recipe "rails_part::pre_script"

application node['deploy_rails_puma']['app_name'] do
  action :deploy
  path node['deploy_rails_puma']['app_path']
  owner node['deploy_rails_puma']['app_user']
  group node['deploy_rails_puma']['app_group']

  repository node['deploy_rails_puma']['deploy']['repository']
  revision node['deploy_rails_puma']['deploy']['revision']

  migrate node['deploy_rails_puma']['deploy']['migrate']
  migration_command node['deploy_rails_puma']['deploy']['migration_command']
  migration_command "#{node['deploy_rails_puma']['deploy']['migration_command']} RAILS_ENV=#{node['deploy_rails_puma']['deploy']['rails_env']}"

  rails do
    database do
      adapter db_params['adapter']
      host db_params['host']
      database db_params['database']
      username db_params['user']
      password db_params['password']
    end
    bundler node['deploy_rails_puma']['rails']['bundler']
    bundle_command node['deploy_rails_puma']['rails']['bundle_command']
  end
end

puma_config node['deploy_rails_puma']['app_name'] do
  directory node['deploy_rails_puma']['app_path']
  environment node['deploy_rails_puma']['deploy']['rails_env']
  bind node['deploy_rails_puma']['puma']['bind']
  daemonize true
  output_append node['deploy_rails_puma']['puma']['output_append']
  monit false
  logrotate node['deploy_rails_puma']['puma']['logrotate']
  thread_min node['deploy_rails_puma']['puma']['thread_min']
  thread_max node['deploy_rails_puma']['puma']['thread_max']
  workers node['deploy_rails_puma']['puma']['workers']
end

template "/etc/init.d/#{node['deploy_rails_puma']['app_name']}" do
  source "puma.erb"
  owner "root"
  group "root"
  mode "0755"
end

bash "add_puma_service" do
  code "chkconfig --add #{node['deploy_rails_puma']['app_name']}"
end

service node['deploy_rails_puma']['app_name'] do
  action :start
  notifies :run, "bash[post_script]", :delayed
end

bash "post_script" do
  action :nothing
  code "#{node['deploy_rails_puma']['post_script']}"
end

include_recipe "rails_part::post_script"
