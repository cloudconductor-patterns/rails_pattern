#
# Cookbook Name:: rails_part
# Recipe:: deploy
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
def dynamic?
  -> (_, application) { application[:type] == 'dynamic' }
end

::Chef::Recipe.send(:include, CloudConductor::CommonHelper)
db_server_info = server_info('db').first

node['cloudconductor']['applications'].select(&dynamic?).each do |app_name, app|

  app_root = "#{node['rails_part']['app']['base_path']}/#{app_name}"
  app_dir = "#{app_root}/releases/#{app['version']}"
  directory "#{app_root}/releases" do
    recursive true
    action :create
  end

  case app['protocol']
  when 'git'
    git app_dir do
      repository app['url']
      revision app['revision']
      action :checkout
    end
  when 'http'
    tmp_dir = "/tmp/#{app_name}"
    directory tmp_dir do
      recursive true
      action :create
    end
    unless Dir.exist?(app_dir)
      remote_file "application_tarball_#{app_name}" do
        source app['url']
        path "#{tmp_dir}/#{app_name}.tar.gz"
      end

      bash "extract_static_files_#{app_name}" do
        code <<-EOS
          tar -zxvf #{tmp_dir}/#{app_name}.tar.gz -C #{tmp_dir}
          rm #{tmp_dir}/#{app_name}.tar.gz
          mv #{tmp_dir}/* #{app_dir}
        EOS
      end
    end
  end

  bash "pre_deploy_script_#{app_name}" do
    cwd app_dir
    code app['pre_deploy']
    only_if { app['pre_deploy'] && !app['pre_deploy'].empty? }
  end

  template "#{app_dir}/config/database.yml" do
    source 'database.yml.erb'
    variables db: node['rails_part']['db'], db_server: db_server_info, environment: node['rails_part']['app']['rails_env']
  end

  bash "bundle_install_#{app_name}" do
    cwd app_dir
    code '/opt/rbenv/shims/bundle install --without test development --path=vendor/bundle'
  end

  bash "db_migrate_#{app_name}" do
    cwd app_dir
    environment 'RAILS_ENV' => node['rails_part']['app']['rails_env'], 'RACK_ENV' => node['rails_part']['app']['rails_env']
    code '/opt/rbenv/shims/bundle exec rake db:migrate'
  end

  link "#{app_root}/current" do
    to app_dir
  end

  puma_config app_name do
    protocol, host, port = node['rails_part']['puma']['bind'].split(':')
    port = app['parameters']['port'] if app['parameters']['port']

    directory     "#{node['rails_part']['app']['base_path']}/#{app_name}"
    environment   node['rails_part']['app']['rails_env']
    bind          "#{protocol}:#{host}:#{port}"
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

  bash "post_deploy_script_#{app_name}" do
    cwd app_dir
    code app['post_deploy']
    only_if { app['post_deploy'] && !app['post_deploy'].empty? }
  end
end
