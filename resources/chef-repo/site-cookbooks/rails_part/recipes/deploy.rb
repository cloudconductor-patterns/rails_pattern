#
# Cookbook Name:: rails_part
# Recipe:: deploy
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

db_params = node['rails_part']['db']

include_recipe "rails_part::pre_script"

application node['rails_part']['app']['name'] do
  action :deploy
  path       node['rails_part']['app']['path']
  owner      node['rails_part']['user']['name']
  group      node['rails_part']['user']['group']
  repository node['rails_part']['app']['repository']
  revision   node['rails_part']['app']['revision']
  migrate    node['rails_part']['app']['migrate']
#  migration_command node['deploy_rails_puma']['deploy']['migration_command']
  migration_command "#{node['rails_part']['app']['migration_command']} RAILS_ENV=#{node['rails_part']['app']['rails_env']}"

  rails do
    database do
      adapter  db_params['adapter']
      host     db_params['host']
      database db_params['database']
      username db_params['user']
      password db_params['password']
    end
    bundler        node['rails_part']['app']['bundler']
    bundle_command node['rails_part']['app']['bundle_command']
  end
end

puma_config node['rails_part']['app']['name'] do
  directory     node['rails_part']['app']['path']
  environment   node['rails_part']['app']['rails_env']
  bind          node['rails_part']['puma']['bind']
  daemonize     true
  output_append node['rails_part']['puma']['output_append']
  monit         false
  logrotate     node['rails_part']['puma']['logrotate']
  thread_min    node['rails_part']['puma']['thread_min']
  thread_max    node['rails_part']['puma']['thread_max']
  workers       node['rails_part']['puma']['workers']
end

template "/etc/init.d/#{node['rails_part']['app']['name']}" do
  source "puma_init_script.erb"
  owner "root"
  group "root"
  mode "0755"
end

bash "add_puma_service" do
  code "chkconfig --add #{node['rails_part']['app']['name']}"
end

service node['rails_part']['app']['name'] do
  action :start
end

include_recipe "rails_part::post_script"
