#
# Cookbook Name:: nginx_part
# Recipe:: deploy
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
file "#{node['nginx']['dir']}/conf.d/default" do
  action :delete
end

node['cloudconductor']['applications'].each do |app_name, app|
  app['name'] = app_name
  app_root = "#{node['nginx']['default_root']}/#{app['name']}/#{app['version']}"
  current_root = "#{node['nginx']['default_root']}/#{app['name']}/current"
  #next if Dir.exist?(app_root) && File.exist?(current_root) && File.realpath(current_root) == app_root

  tmp_dir = "#{node['nginx_part']['tmp_dir']}/#{app['name']}"
  directory tmp_dir do
    recursive true
  end

  directory app_root do
    recursive true
  end

  if !Dir.exist?(app_root) || app['force_update']
    remote_type = app['remote_type'] || 'http'
    case remote_type
    when 'http'
      remote_file 'application_tarball' do
        source app['remote_url']
        path "#{tmp_dir}/#{app['name']}.tar.gz"
      end
    when 'git'
      git 'application_repository' do
        repository app['remote_url']
        revision app['remote_revision'] || 'HEAD'
        destination "#{tmp_dir}/#{app['name']}"
        action :export
      end
    end

    bash 'extract_static_files' do
      code <<-EOS
        tar -zxvf #{tmp_dir}/#{app['name']}.tar.gz -C #{tmp_dir}
        rm #{tmp_dir}/#{app['name']}.tar.gz
        if [ -d #{tmp_dir}/*/public ]; then
          mv #{tmp_dir}/*/public/* #{app_root}/
        else
          mv #{tmp_dir}/*/* #{app_root}/
        fi
      EOS
    end
  end

  options = { server_tokens: 'off' }
  if app['basic_auth']
    package 'httpd-tools'
    bash 'create_htpasswd' do
      code "htpasswd -cb #{node['nginx']['dir']}/htpasswd #{app['auth_user']} #{app['auth_password']}"
    end
    options.merge(
      basic_auth: 'Restricted',
      basic_auth_user_file: 'htpasswd'
    )
  end

  if app['type'] == 'dynamic'
    upstream_hash = {
      "#{app['name']}" => {
        server: "#{node['cloudconductor']['ap_host']}:8080"
      }
    }
    locations_hash = {
      '/' => {
        proxy_pass: "http://#{app['name']}",
        'proxy_set_header Host' => '$http_host',
        'proxy_set_header X-Real-IP' => '$remote_addr',
        'proxy_set_header X-Forwarded-For' => '$proxy_add_x_forwarded_for',
        'proxy_set_header X-Forwarded-Proto' => '$scheme'
      },
      '/static' => {
        root: "#{app_root}",
        index: 'index.html'
      }
    }
    options.merge(upstream_hash)
    nginx_conf_file app['domain_name'] do
      upstream upstream_hash
      locations locations_hash
      options options
    end
  else
    nginx_conf_file app['domain_name'] do
      root "#{app_root}"
      options options
      site_type :static
    end
  end

  link current_root do
    to app_root
  end

  service "nginx" do
    action :restart
  end
end
