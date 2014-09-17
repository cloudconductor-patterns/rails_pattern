#
# Cookbook Name:: rails_part
# Recipe:: deploy
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

app_name, app = node['cloudconductor']['applications'].find { |_app_name, app| app['type'] != 'static' }
db = node['rails_part']['db']
cloudconductor = node['cloudconductor']

bash 'pre_deploy_script' do
  code app['pre_deploy']
  only_if { app['pre_deploy'] && !app['pre_deploy'].empty? }
end

case app['protocol']
when 'git'
  application app_name do
    action :deploy
    path "#{node['rails_part']['app']['base_path']}/#{app_name}"
    owner node['rails_part']['user']['name']
    group node['rails_part']['user']['group']
    repository app['url']
    revision app['revision'] || 'HEAD'
    migrate node['rails_part']['app']['migrate']
    # migration_command node['rails_part']['app']['migration_command']
    migration_command '/opt/rbenv/shims/bundle exec rake db:migrate 2>&1 > /tmp/test.log'
    environment_name node['rails_part']['app']['rails_env']

    rails do
      database do
        adapter db['adapter']
        host cloudconductor['db_host']
        database db['database']
        username db['user']
        password db['password']
      end
      bundler node['rails_part']['app']['bundler']
      bundle_command node['rails_part']['app']['bundle_command']
    end
  end
when 'http'
  tmp_dir = "/tmp/#{app_name}"
  directory tmp_dir do
    recursive true
    action :create
  end

  app_root = "#{node['rails_part']['app']['base_path']}/#{app_name}"
  app_dir = "#{app_root}/releases/#{app['version']}"

  directory "#{app_root}/releases" do
    recursive true
    action :create
  end

  unless Dir.exist?(app_dir)
    remote_file 'application_tarball' do
      source app['url']
      path "#{tmp_dir}/#{app_name}.tar.gz"
    end

    bash 'extract_static_files' do
      code <<-EOS
        tar -zxvf #{tmp_dir}/#{app_name}.tar.gz -C #{tmp_dir}
        rm #{tmp_dir}/#{app_name}.tar.gz
        mv #{tmp_dir}/* #{app_dir}
      EOS
    end
  end

  template "#{app_dir}/config/database.yml" do
    source 'database.yml.erb'
    variables db: node['rails_part']['db'], environment: node['rails_part']['app']['rails_env']
  end

  bash 'bundle_install' do
    cwd app_dir
    code '/opt/rbenv/shims/bundle install --without test development'
  end

  bash 'db_migrate' do
    cwd app_dir
    environment 'RAILS_ENV' => node['rails_part']['app']['rails_env']
    code '/opt/rbenv/shims/bundle exec rake db:migrate'
  end

  link "#{app_root}/current" do
    to app_dir
  end
end

puma_config app_name do
  directory     "#{node['rails_part']['app']['base_path']}/#{app_name}"
  environment   node['rails_part']['app']['rails_env']
  bind          node['rails_part']['puma']['bind']
  output_append node['rails_part']['puma']['output_append']
  logrotate     node['rails_part']['puma']['logrotate']
  thread_min    node['rails_part']['puma']['thread_min']
  thread_max    node['rails_part']['puma']['thread_max']
  workers       node['rails_part']['puma']['workers']
  daemonize     true
  monit         false
end

template "/etc/init.d/#{app_name}" do
  source 'puma_init_script.erb'
  owner 'root'
  group 'root'
  mode '0755'
  variables(
    app_name: app_name,
    app_path: "#{node['rails_part']['app']['base_path']}/#{app_name}",
    environment: node['rails_part']['app']['rails_env']
  )
end

service app_name do
  action [:enable, :start]
end

bash 'post_deploy_script' do
  code app['post_deploy']
  only_if { app['post_deploy'] && !app['post_deploy'].empty? }
end
