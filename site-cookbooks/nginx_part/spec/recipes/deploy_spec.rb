require_relative '../spec_helper'

describe 'nginx_part::deploy' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  nginx_dir = '/etc/nginx'

  before do
    chef_run.converge(described_recipe)
  end

  it 'delete default.conf' do
    chef_run.node.set['nginx']['dir'] = nginx_dir
    chef_run.converge(described_recipe)
    expect(chef_run).to delete_file("#{nginx_dir}/conf.d/default.conf")
  end

  describe 'applications are included in "cloudconductor applications"' do
    nginx_default_root = '/var/www/nginx-default'
    app_name = 'application'
    app_version = '0.3'
    app_archive_url = 'http://cloudconductor.org/chefspec.tar.gz'
    domain = 'cloudconductor.org'
    ap_server_ip = '172.0.0.5'

    before do
      allow_any_instance_of(Chef::Recipe).to receive(:server_info)
        .with('ap').and_return([{ hostname: 'ap_svr', roles: 'ap', private_ip: ap_server_ip }])

      allow(Dir).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).and_call_original

      chef_run.node.set['nginx']['default_root'] = nginx_default_root
      chef_run.node.set['cloudconductor']['applications'] = {
        app_name => {
          version: app_version,
          force_update: false,
          url: app_archive_url,
          domain: domain,
          parameters: {}
        }
      }
      chef_run.converge(described_recipe)
    end

    describe 'application deploy is the first time'do
      tmp_dir = '/tmp/nginx'

      before do
        allow(Dir).to receive(:exist?).with("#{nginx_default_root}/#{app_name}/#{app_version}").and_return(false)
      end

      it 'create tmp directory'do
        chef_run.node.set['nginx_part']['tmp_dir'] = tmp_dir
        chef_run.converge(described_recipe)
        expect(chef_run).to create_directory("#{tmp_dir}/#{app_name}").with(recursive: true)
      end

      it 'create application root directory' do
        expect(chef_run).to create_directory("#{nginx_default_root}/#{app_name}/#{app_version}").with(
          recursive: true
        )
      end

      describe 'deploy protocol is http' do
        before do
          chef_run.node.set['cloudconductor']['applications'][app_name]['protocol'] = 'http'
          chef_run.converge(described_recipe)
        end

        it 'download application archive file at http' do
          expect(chef_run).to create_remote_file('application_tarball').with(
            source: app_archive_url,
            path: "#{tmp_dir}/#{app_name}/#{app_name}.tar.gz"
          )
        end
      end

      describe 'deploy protocol is git' do
        repository_url = 'https://github.com/cloudconductor-patterns/rails_pattern.git'

        before do
          chef_run.node.set['cloudconductor']['applications'][app_name]['protocol'] = 'git'
          chef_run.node.set['cloudconductor']['applications'][app_name]['url'] =  repository_url
          chef_run.converge(described_recipe)
        end

        describe 'revision is set' do
          revision = 'e105abce8de7784d2e551613272f0d83bb92cc41'

          before do
            chef_run.node.set['cloudconductor']['applications'][app_name]['revision'] = revision
            chef_run.converge(described_recipe)
          end

          it 'download application of the specified revision at git' do
            expect(chef_run).to export_git('application_repository').with(
              repository: repository_url,
              revision: revision,
              destination: "#{tmp_dir}/#{app_name}/#{app_name}"
            )
          end
        end

        describe 'revision is not set' do
          before do
            chef_run.node.set['cloudconductor']['applications'][app_name]['revision'] = nil
            chef_run.converge(described_recipe)
          end

          it 'download application of the HEAD revision at git' do
            expect(chef_run).to export_git('application_repository').with(
              repository: repository_url,
              revision: 'HEAD',
              destination: "#{tmp_dir}/#{app_name}/#{app_name}"
            )
          end
        end
      end

      describe 'deploy protocol is not set' do
        before do
          chef_run.node.set['cloudconductor']['applications'][app_name]['protocol'] = nil
          chef_run.converge(described_recipe)
        end

        it 'download application archive file at http' do
          expect(chef_run).to create_remote_file('application_tarball').with(
            source: app_archive_url,
            path: "#{tmp_dir}/#{app_name}/#{app_name}.tar.gz"
          )
        end
      end

      it 'extract the application from the archive file at http' do
        expect(chef_run).to run_bash('extract_static_files')
      end

      describe 'enable basic auth'do
        before do
          chef_run.node.set['cloudconductor']['applications'][app_name]['parameters']['basic_auth'] = 'Restricted'
          chef_run.converge(described_recipe)
        end

        it 'install httpd-tools' do
          expect(chef_run).to install_package('httpd-tools')
        end

        it 'create htpasswd file' do
          auth_user = 'auth_user'
          auth_pass = 'auth_pass'

          chef_run.node.set['cloudconductor']['applications'][app_name]['parameters']['auth_user'] = auth_user
          chef_run.node.set['cloudconductor']['applications'][app_name]['parameters']['auth_password'] = auth_pass
          chef_run.converge(described_recipe)

          expect(chef_run).to run_bash('create_htpasswd').with(
            code: "htpasswd -cb #{nginx_dir}/htpasswd #{auth_user} #{auth_pass}"
          )
        end
      end

      describe 'disable basic auth'do
        before do
          chef_run.node.set['cloudconductor']['applications'][app_name]['parameters']['basic_auth'] = nil
          chef_run.converge(described_recipe)
        end

        it 'not install httpd-tools' do
          expect(chef_run).to_not install_package('httpd-tools')
        end

        it 'not create htpasswd file' do
          expect(chef_run).to_not run_bash('create_htpasswd')
        end
      end

      describe 'application type is dynamic' do
        app_port = 8081

        before do
          chef_run.node.set['cloudconductor']['applications'][app_name]['type'] = 'dynamic'
          chef_run.node.set['cloudconductor']['applications'][app_name]['parameters']['port'] = app_port
          chef_run.converge(described_recipe)
        end

        it 'nginx default listen setting is 80'do
          expect(chef_run.node['nginx_conf']['listen']).to eq('80')
        end

        it 'create nginx conf file' do
          expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
            :nginx_conf_file,
            :create,
            domain
          ).with(
            upstream: {
              app_name => {
                server: "#{ap_server_ip}:#{app_port}"
              }
            },
            locations: {
              '/' => {
                proxy_pass: "http://#{app_name}",
                'proxy_set_header Host' => '$http_host',
                'proxy_set_header X-Real-IP' => '$remote_addr',
                'proxy_set_header X-Forwarded-For' => '$proxy_add_x_forwarded_for',
                'proxy_set_header X-Forwarded-Proto' => '$scheme'
              },
              '/static' => {
                'alias' => "#{nginx_default_root}/#{app_name}/#{app_version}",
                index: 'index.html'
              },
              '/_errors/502.html' => {
                'alias' => "#{nginx_default_root}/maintenance/index.html",
                block: 'internal'
              }
            },
            listen: '80',
            options: {
              server_tokens: 'off',
              error_page: '502 = /_errors/502.html'
            }
          )
        end
      end

      describe 'application type is static' do
        before do
          chef_run.node.set['cloudconductor']['applications'][app_name]['type'] = 'static'
          chef_run.converge(described_recipe)
        end

        it 'nginx default listen setting is 80'do
          expect(chef_run.node['nginx_conf']['listen']).to eq('80')
        end

        it 'create nginx conf file' do
          expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
            :nginx_conf_file,
            :create,
            domain
          ).with(
            root: "#{nginx_default_root}/#{app_name}/#{app_version}",
            site_type: :static,
            listen: '80',
            options: {
              server_tokens: 'off',
              error_page: '502 = /_errors/502.html'
            }
          )
        end

        describe 'set default server setting' do
          it 'create nginx conf file include "default server" to settings' do
            chef_run.node.set['cloudconductor']['applications'][app_name]['parameters']['default_server'] = true
            chef_run.converge(described_recipe)
            expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
              :nginx_conf_file,
              :create,
              domain
            ).with(
              listen: '80 default_server'
            )
          end
        end

        describe 'enable basic auth' do
          it 'create nginx conf file include "auth setting" to settings' do
            chef_run.node.set['cloudconductor']['applications'][app_name]['parameters']['basic_auth'] = 'Restricted'
            chef_run.converge(described_recipe)
            expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
              :nginx_conf_file,
              :create,
              domain
            ).with(
              options: {
                server_tokens: 'off',
                error_page: '502 = /_errors/502.html',
                auth_basic: 'Restricted',
                auth_basic_user_file: 'htpasswd'
              }
            )
          end
        end

        describe 'set client max body size' do
          it 'create nginx conf file include "Max body size setting" to settings' do
            max_body_size = 1024
            chef_run.node.set['cloudconductor']['applications'][app_name]['parameters']['client_max_body_size'] = max_body_size
            chef_run.converge(described_recipe)

            expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
              :nginx_conf_file,
              :create,
              domain
            ).with(
              options: {
                server_tokens: 'off',
                error_page: '502 = /_errors/502.html',
                client_max_body_size: max_body_size
              }
            )
          end
        end
      end

      it 'create link to application hosting directory from application directory' do
        expect(chef_run.link("#{nginx_default_root}/#{app_name}/current")).to \
          link_to("#{nginx_default_root}/#{app_name}/#{app_version}")
      end

      it 'restart the nginx service' do
        expect(chef_run).to restart_service('nginx')
      end
    end

    describe 'the application status is force update' do
      before do
        chef_run.node.set['cloudconductor']['applications'][app_name]['force_update'] =  true
        chef_run.converge(described_recipe)
      end

      it 'start the building'do
        chef_run.node.set['nginx_part']['tmp_dir'] = '/tmp'
        chef_run.converge(described_recipe)
        expect(chef_run).to create_directory("/tmp/#{app_name}")
      end
    end

    describe 'version of deploy application is different from the current application version' do
      deploy_version = '0.3'
      current_version = '0.1'

      before do
        allow(Dir).to receive(:exist?).with("#{nginx_default_root}/#{app_name}/#{deploy_version}").and_return(true)
        allow(File).to receive(:exist?).with("#{nginx_default_root}/#{app_name}/current").and_return(true)
        allow(File).to receive(:realpath).with("#{nginx_default_root}/#{app_name}/current")
          .and_return("#{nginx_default_root}/#{app_name}/#{current_version}")
      end

      it 'start the building'do
        chef_run.node.set['nginx_part']['tmp_dir'] = '/tmp'
        chef_run.converge(described_recipe)

        expect(chef_run).to create_directory("/tmp/#{app_name}")
      end
    end

    describe 'otherwise' do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(Dir).to receive(:exist?).with("#{nginx_default_root}/#{app_name}/#{app_version}").and_return(true)
        allow(File).to receive(:exist?).with("#{nginx_default_root}/#{app_name}/current").and_return(true)
        allow(File).to receive(:realpath).with("#{nginx_default_root}/#{app_name}/current")
          .and_return("#{nginx_default_root}/#{app_name}/#{app_version}")

        chef_run.converge(described_recipe)
      end

      it 'not start the building'do
        chef_run.node.set['nginx_part']['tmp_dir'] = '/tmp'
        chef_run.converge(described_recipe)

        expect(chef_run).to_not create_directory("/tmp/#{app_name}")
      end
    end
  end
end
