require_relative '../spec_helper'

describe 'rails_part::deploy' do
  let(:chef_run) do
    runner = ChefSpec::Runner.new(
      cookbook_path: %w[site-cookbooks cookbooks],
      platform:      'centos',
      version:       '6.5'
    ) do |node|
      node.set['rails_part']['app']['base_path'] = '/var/www'
      node.set['cloudconductor']['applications'] = {
        dynamic_git_app: {
          type: 'dynamic',
          protocol: 'git',
          url: 'http://github.com/foo.git',
          pre_deploy: 'date',
          post_deploy: 'ifconfig',
          parameters: {
            port: '8080'
          }
        },
        dynamic_http_app: {
          type: 'dynamic',
          protocol: 'http',
          url: 'http://localhost/foo.tar.gz',
          version: '1.0',
          pre_deploy: 'date',
          post_deploy: 'ifconfig',
          parameters: {
            port: '8080'
          }
        }
      }
    end
    runner.converge(described_recipe)
  end

  before do
    Chef::Recipe.any_instance.stub(:server_info).with('db').and_return(
      [{ hostname: 'db', roles: 'db', private_ip: '127.0.0.1' }]
    )
  end

  it 'bash pre deploy script' do
    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :bash,
      :run,
      'pre_deploy_script_dynamic_git_app'
    ).with(
      code: 'date'
    )
  end

  describe 'application deploy from git' do
    it 'deploy rails application' do
      expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
        :application,
        :deploy,
        'dynamic_git_app'
      ).with(
        path:       '/var/www/dynamic_git_app',
        owner:      'rails',
        group:      'rails',
        repository: 'http://github.com/foo.git',
        revision:   'HEAD',
        migrate:    true,
        migration_command: '/opt/rbenv/shims/bundle exec rake db:migrate 2>&1 > /tmp/test.log',
        environment_name: 'production'
      )
    end
  end

  describe 'application deploy from http' do
    it 'create tmp directory' do
      expect(chef_run).to create_directory('/tmp/dynamic_http_app').with(
        recursive: true
      )
    end

    it 'create app directory' do
      expect(chef_run).to create_directory('/var/www/dynamic_http_app/releases').with(
        recursive: true
      )
    end

    it 'download source archve file' do
      expect(chef_run).to create_remote_file('application_tarball_dynamic_http_app').with(
        source: 'http://localhost/foo.tar.gz',
        path: '/tmp/dynamic_http_app/dynamic_http_app.tar.gz'
       )
    end

    it 'extract_static_files_dynamic_http_app' do
      app_name = 'dynamic_http_app'
      tmp_dir = "/tmp/#{app_name}"
      app_dir = "/var/www/#{app_name}/releases/1.0"

      expect(chef_run).to run_bash('extract_static_files_dynamic_http_app').with(
        code: <<-EOS
          tar -zxvf #{tmp_dir}/#{app_name}.tar.gz -C #{tmp_dir}
          rm #{tmp_dir}/#{app_name}.tar.gz
          mv #{tmp_dir}/* #{app_dir}
        EOS
       )
    end

    it 'create database config' do
      expect(chef_run).to \
        create_template('/var/www/dynamic_http_app/releases/1.0/config/database.yml').with(
          source: 'database.yml.erb',
          variables: {
            db: {
              "adapter" =>  'mysql2',
              "database" => 'rails',
              "user" =>  'rails',
              "password" =>  'todo_replace_randompassword'
            },
            db_server: {
              hostname: 'db',
              roles: 'db',
              private_ip: '127.0.0.1'
            },
            environment: 'production'
          }
        )
    end

    it 'bundle install' do
      expect(chef_run).to run_bash('bundle_install_dynamic_http_app').with(
        cwd: '/var/www/dynamic_http_app/releases/1.0',
        code: '/opt/rbenv/shims/bundle install --without test development --path=vendor/bundle'
      )
    end

    it 'db migration' do
      expect(chef_run).to run_bash('db_migrate_dynamic_http_app').with(
        cwd: '/var/www/dynamic_http_app/releases/1.0',
        environment: { 'RAILS_ENV' => 'production' },
        code: '/opt/rbenv/shims/bundle exec rake db:migrate'
      )
    end

    it 'create a link to the application current' do
      link = chef_run.link('/var/www/dynamic_http_app/current')
      expect(link).to link_to('/var/www/dynamic_http_app/releases/1.0')
    end
  end

  it 'create init.d file of puma' do
    expect(chef_run).to create_template('/etc/init.d/dynamic_git_app').with(
      source: 'puma_init_script.erb',
      owner:  'root',
      group:  'root',
      mode:   '0755',
      variables: {
        app_name: 'dynamic_git_app',
        app_path: '/var/www/dynamic_git_app',
        environment: 'production'
      }
    )
  end

  it 'start puma service' do
    expect(chef_run).to start_service('dynamic_git_app')
  end

  it 'bash post deploy script' do
    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :bash,
      :run,
      'post_deploy_script_dynamic_git_app'
    ).with(
      code: 'ifconfig'
    )
  end
end
