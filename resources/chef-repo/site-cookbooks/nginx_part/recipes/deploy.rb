#
# Cookbook Name:: nginx_part
# Recipe:: deploy
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
file "#{node['nginx']['dir']}/conf.d/default.conf" do
  action :delete
end

node['cloudconductor']['applications'].each do |app_name, app|
  app_root = "#{node['nginx']['default_root']}/#{app_name}/#{app['version']}"
  current_root = "#{node['nginx']['default_root']}/#{app_name}/current"
  next if !app['force_update'] && Dir.exist?(app_root) && File.exist?(current_root) && File.realpath(current_root) == app_root

  tmp_dir = "#{node['nginx_part']['tmp_dir']}/#{app_name}"
  directory tmp_dir do
    recursive true
  end

  directory app_root do
    recursive true
  end

  if !Dir.exist?(app_root) || app['force_update']
    protocol = app['protocol'] || 'http'
    case protocol
    when 'http'
      remote_file 'application_tarball' do
        source app['url']
        path "#{tmp_dir}/#{app_name}.tar.gz"
      end
    when 'git'
      git 'application_repository' do
        repository app['url']
        revision app['revision'] || 'HEAD'
        destination "#{tmp_dir}/#{app_name}"
        action :export
      end
    end

    bash 'extract_static_files' do
      code <<-EOS
        tar -zxvf #{tmp_dir}/#{app_name}.tar.gz -C #{tmp_dir}
        rm #{tmp_dir}/#{app_name}.tar.gz
        cd #{tmp_dir}/*
        if [ $? -eq 0 ]; then
          if [ -d ./public ]; then
            mv ./public/* #{app_root}/
          else
            mv ./* #{app_root}/
          fi
        fi
      EOS
    end
  end

  options = { server_tokens: 'off' }
  if app['parameters']['basic_auth']
    package 'httpd-tools'
    bash 'create_htpasswd' do
      code "htpasswd -cb #{node['nginx']['dir']}/htpasswd #{app['parameters']['auth_user']} #{app['parameters']['auth_password']}"
    end
    options.merge(
      basic_auth: 'Restricted',
      basic_auth_user_file: 'htpasswd'
    )
  end

  if app['type'] == 'dynamic'
    upstream_hash = {
      "#{app_name}" => {
        server: "#{node['cloudconductor']['ap_host']}:8080"
      }
    }
    locations_hash = {
      '/' => {
        proxy_pass: "http://#{app_name}",
        'proxy_set_header Host' => '$http_host',
        'proxy_set_header X-Real-IP' => '$remote_addr',
        'proxy_set_header X-Forwarded-For' => '$proxy_add_x_forwarded_for',
        'proxy_set_header X-Forwarded-Proto' => '$scheme'
      },
      '/static' => {
        'alias' => "#{app_root}",
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
