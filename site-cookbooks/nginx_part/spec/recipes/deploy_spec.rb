require_relative '../spec_helper'

describe 'nginx_part::deploy' do
  # attribute node.set
  let(:chef_run_dynamic) do
    ChefSpec::SoloRunner.new(cookbook_path: ['cookbooks', 'site-cookbooks']) do |node|
      node.set['nginx']['dir'] = '/etc/nginx'
      node.set['nginx_part']['tmp_dir'] = '/tmp/work'
      node.set['nginx']['default_root'] = '/var/www'
      node.set['cloudconductor']['applications'] = {
        test_dynamic_app: {
          version: '1.0.0',
          protocol: 'http',
          revision: 'HEAD',
          url: 'https://github.com/cloudconductor-patterns/rails_pattern.git',
          parameters: {
            default_server: '127.0.0.1',
            port: '8080',
            basic_auth: true,
            auth_user: 'usr',
            auth_password: 'passwd'
          },
          type: 'dynamic',
          domain: 'test'
        }
      }
      node.set['option'] = {
        server_tokens: 'off',
        auth_basic: 'Restricted',
        auth_basic_user_file: 'htpasswd'
      }
      node.set['nginx_conf']['listen'] = '80'
      node.set['cloudconductor']['servers'] = {
        ap_svr: {
          roles: 'ap',
          hostname: 'ap_svr',
          private_ip: '10.0.0.3'
        },
        zbx_svr: {
          roles: 'monitoring',
          hostname: 'zbx_error',
          private_ip: '10.0.0.5'
        }
      }
      node.set['listen'] = '80 default_server'
      node.set['options'] = {
        server_tokens: 'off',
        auth_basic: 'Restricted',
        auth_basic_user_file: 'htpasswd'
      }
      node.set['upstream_hash'] = {
        'test_dynamic_app' => {
          server: '10.0.0.3:8080 || 8080'
        }
      }
      node.set['locations_hash'] = {
        '/' => {
          proxy_pass: 'http://test_dynamic_app',
          'proxy_set_header Host' => '$http_host',
          'proxy_set_header X-Real-IP' => '$remote_addr',
          'proxy_set_header X-Forwarded-For' => '$proxy_add_x_forwarded_for',
          'proxy_set_header X-Forwarded-Proto' => '$scheme'
        },
        '/static' => {
          'alias' => '/var/www/test_dynamic_app/1.0.0',
          index: 'index.html'
        }
      }
    end.converge 'nginx_part::deploy'
  end
  let(:chef_run_static) do
    ChefSpec::SoloRunner.new(cookbook_path: ['cookbooks', 'site-cookbooks']) do |node|
      node.set['nginx']['dir'] = '/etc/nginx'
      node.set['nginx_part']['tmp_dir'] = '/tmp/work'
      node.set['nginx']['default_root'] = '/var/www'
      node.set['cloudconductor']['applications'] = {
        test_app: {
          version: '1.0.0',
          protocol: 'http',
          revision: 'HEAD',
          url: 'https://github.com/cloudconductor-patterns/rails_pattern.git',
          parameters: {
            default_server: '127.0.0.1',
            port: '8080',
            basic_auth: true,
            auth_user: 'usr',
            auth_password: 'passwd'
          },
          type: 'static',
          domain: 'test'
        }
      }
      node.set['option'] = {
        server_tokens: 'off',
        auth_basic: 'Restricted',
        auth_basic_user_file: 'htpasswd'
      }
      node.set['nginx_conf']['listen'] = '80'
      node.set['cloudconductor']['servers'] = {
        ap_svr: {
          roles: 'ap',
          private_ip: '10.0.0.3',
          hostname: 'ap_svr'
        },
        zbx_svr: {
          roles: 'monitoring',
          private_ip: '10.0.0.5',
          hostname: 'zbx_error'
        }
      }
      node.set['listen'] = '80 default_server'
      node.set['options'] = {
        server_tokens: 'off',
        auth_basic: 'Restricted',
        auth_basic_user_file: 'htpasswd'
      }
    end.converge 'nginx_part::deploy'
  end

  before do
#    Chef::Recipe.any_instance.stub(:server_info).with('ap').and_return(
    allow_any_instance_of(Chef::Recipe).to receive(:server_info).with('ap').and_return(
      [{ hostname: 'ap_svr', roles: 'ap', private_ip: '10.0.0.3' }]
    )
  end

  # chef_run_dynamic nginx_part::deploy
  # Delete /etc/nginx/conf.d/default.conf
  it 'Delete /etc/nginx/conf.d/default.conf' do
    expect(chef_run_dynamic).to delete_file('/etc/nginx/conf.d/default.conf')
  end

  it 'Create tmp_dir' do
    expect(chef_run_dynamic).to create_directory('/tmp/work/test_dynamic_app').with(
      recursive: true
    )

    expect(chef_run_dynamic).to_not create_directory('/tmp/work/test_dynamic_app').with(
      recursive: false
    )
  end

  it 'Create app_root' do
    expect(chef_run_dynamic).to create_directory('/var/www/test_dynamic_app/1.0.0').with(
      recursive: true
    )

    expect(chef_run_dynamic).to_not create_directory('/var/www/test_dynamic_app/1.0.0').with(
      recursive: false
    )
  end

  it 'Create remote_file with application_tarball' do
    expect(chef_run_dynamic).to create_remote_file('/tmp/work/test_dynamic_app/test_dynamic_app.tar.gz')
  end

  describe 'app["type"] is dynamic' do
    it 'Add static file for application in dynamic' do
      expect(chef_run_dynamic).to run_bash('extract_static_files').with(
        code: <<-EOS
        tar -zxvf /tmp/work/test_dynamic_app/test_dynamic_app.tar.gz -C /tmp/work/test_dynamic_app
        rm /tmp/work/test_dynamic_app/test_dynamic_app.tar.gz
        cd /tmp/work/test_dynamic_app/*
        if [ $? -eq 0 ]; then
          if [ -d ./public ]; then
            mv ./public/* /var/www/test_dynamic_app/1.0.0/
          else
            mv ./* /var/www/test_dynamic_app/1.0.0/
          fi
        fi
      EOS
      )
    end
  end
  describe 'app["type"] is static' do
    it 'Add static file for application in static' do
      expect(chef_run_static).to run_bash('extract_static_files').with(
        code: <<-EOS
        tar -zxvf /tmp/work/test_app/test_app.tar.gz -C /tmp/work/test_app
        rm /tmp/work/test_app/test_app.tar.gz
        cd /tmp/work/test_app/*
        if [ $? -eq 0 ]; then
          if [ -d ./public ]; then
            mv ./public/* /var/www/test_app/1.0.0/
          else
            mv ./* /var/www/test_app/1.0.0/
          fi
        fi
      EOS
      )
    end
  end
  it 'install httpd-tools with the default action' do
    expect(chef_run_dynamic).to install_package('httpd-tools')
    expect(chef_run_dynamic).to_not install_package('httpd_tools')
  end

  it 'create htpasswd' do
    expect(chef_run_dynamic).to run_bash('create_htpasswd').with(
      code: 'htpasswd -cb /etc/nginx/htpasswd usr passwd'
    )

    expect(chef_run_dynamic).to_not run_bash('create_htpasswd').with(
      code: 'htpasswd -cb /etc/nginx/htpasswd foo bar'
    )
  end

  describe "test for app['type'] eq dynamic" do
    it 'Create nginx_conf_file["test"] in /etc/nginx/sites-available/test in dynamic' do
      expect(chef_run_dynamic).to ChefSpec::Matchers::ResourceMatcher.new(:nginx_conf_file, :create, 'test').with(
        upstream: {
          'test_dynamic_app' => {
            server: '10.0.0.3:8080'
          }
        },
        locations: {
          '/' => {
            proxy_pass: 'http://test_dynamic_app',
            'proxy_set_header Host' => '$http_host',
            'proxy_set_header X-Real-IP' => '$remote_addr',
            'proxy_set_header X-Forwarded-For' => '$proxy_add_x_forwarded_for',
            'proxy_set_header X-Forwarded-Proto' => '$scheme'
          },
          '/static' => {
            'alias' => '/var/www/test_dynamic_app/1.0.0',
            index: 'index.html'
          },
          '/_errors/502.html' => {
            'alias' => '/var/www/maintenance/index.html',
            block: 'internal'
          }
        },
        options: {
          server_tokens: 'off',
          error_page: '502 = /_errors/502.html',
          auth_basic: 'Restricted',
          auth_basic_user_file: 'htpasswd'
        },
        listen: '80 default_server'
      )
    end
  end
  describe "test for app['type'] eq static" do
    it 'Create nginx_conf_file["test"] in /etc/nginx/sites-available/test in static' do
      expect(chef_run_static).to ChefSpec::Matchers::ResourceMatcher.new(:nginx_conf_file, :create, 'test').with(
        root: '/var/www/test_app/1.0.0',
        options: {
          server_tokens: 'off',
          error_page: '502 = /_errors/502.html',
          auth_basic: 'Restricted',
          auth_basic_user_file: 'htpasswd'
        },
        site_type: :static,
        listen: '80 default_server'
      )
    end
  end

  it 'Create symbolic link test' do
    link = chef_run_dynamic.link('/var/www/test_dynamic_app/current')
    expect(link).to link_to('/var/www/test_dynamic_app/1.0.0')
    expect(link).to_not link_to('/var/www/test_dynamic_app/0.0.0')
  end

  it 'Service nginx restart' do
    expect(chef_run_dynamic).to restart_service('nginx')
    expect(chef_run_dynamic).to_not restart_service('not_nginx')
  end

end
