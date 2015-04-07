require_relative '../spec_helper'

describe 'rails_part::deploy' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  describe 'dynamic type applications are included in "cloudconductor applications"' do
    application_name = 'application_name'
    base_path = '/var/www'
    app_version = '0.3'

    before do
      chef_run.node.set['cloudconductor']['applications'] = {
        application_name => {
          type: 'dynamic',
          version: app_version,
          parameters: {}
        }
      }
      chef_run.node.set['rails_part']['app']['base_path'] = base_path
      chef_run.converge(described_recipe)
    end

    it 'create release directory' do
      expect(chef_run).to create_directory("#{base_path}/#{application_name}/releases").with(
        recursive: true
      )
    end

    describe 'application deploy prptocol is git' do
      before do
        chef_run.node.set['cloudconductor']['applications'][application_name]['protocol'] = 'git'
        chef_run.converge(described_recipe)
      end

      it 'checkout application' do
        url = 'https://github.com/cloudconductor-patterns/rails_pattern.git'
        revision = 'e105abce8de7784d2e551613272f0d83bb92cc41'

        chef_run.node.set['cloudconductor']['applications'][application_name]['url'] = url
        chef_run.node.set['cloudconductor']['applications'][application_name]['revision'] = revision
        chef_run.converge(described_recipe)

        expect(chef_run).to checkout_git("#{base_path}/#{application_name}/releases/#{app_version}").with(
          repository: url,
          revision: revision
        )
      end
    end

    describe 'application deploy protocol is http' do
      url = 'http://cloudconductor.org/chefspectest.tar.gz'

      before do
        chef_run.node.set['cloudconductor']['applications'][application_name]['protocol'] = 'http'
        chef_run.node.set['cloudconductor']['applications'][application_name]['url'] = url
        chef_run.converge(described_recipe)
      end

      it 'create tmp directory' do
        expect(chef_run).to create_directory("/tmp/#{application_name}").with(
          recursive: true
        )
      end

      describe 'application directory is not exist' do
        before do
          allow(Dir).to receive(:exist?).with("#{base_path}/#{application_name}/releases/#{app_version}").and_return(false)
        end

        it 'download the application archve file' do
          expect(chef_run).to create_remote_file("application_tarball_#{application_name}").with(
            source: url,
            path: "/tmp/#{application_name}/#{application_name}.tar.gz"
          )
        end

        it 'extract the application from the archive file' do
          tmp_dir = "/tmp/#{application_name}"
          app_dir = "#{base_path}/#{application_name}/releases/#{app_version}"

          expect(chef_run).to run_bash("extract_static_files_#{application_name}").with(
            code: <<-EOS
          tar -zxvf #{tmp_dir}/#{application_name}.tar.gz -C #{tmp_dir}
          rm #{tmp_dir}/#{application_name}.tar.gz
          mv #{tmp_dir}/* #{app_dir}
        EOS
          )
        end
      end

      describe 'application directory is exist' do
        before do
          allow(Dir).to receive(:exist?).with("#{base_path}/#{application_name}/releases/#{app_version}").and_return(true)
          chef_run.converge(described_recipe)
        end

        it 'not download the application archive file' do
          expect(chef_run).to_not create_remote_file("application_tarball_#{application_name}")
        end

        it 'does not extract the application from the archive file' do
          expect(chef_run).to_not run_bash("extract_static_files_#{application_name}")
        end
      end
    end

    it 'run pre_deploy script' do
      command = 'pwd'
      chef_run.node.set['cloudconductor']['applications'][application_name]['pre_deploy'] = command
      chef_run.converge(described_recipe)

      expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
        :bash,
        :run,
        "pre_deploy_script_#{application_name}"
      ).with(
        code: command
      )
    end

    it 'create database.yml' do
      db_server_info = { hostname: 'db', roles: 'db', private_ip: '127.0.0.10' }
      allow_any_instance_of(Chef::Recipe).to receive(:server_info).with('db').and_return([db_server_info])

      db_settings = {
        'adapter' => 'mysql2',
        'database' => 'rails',
        'user' => 'rails'
      }
      rails_env = 'production'

      chef_run.node.set['rails_part']['db'] = db_settings
      chef_run.node.set['rails_part']['app']['rails_env'] = rails_env
      chef_run.converge(described_recipe)

      expect(chef_run).to create_template("#{base_path}/#{application_name}/releases/#{app_version}/config/database.yml").with(
        variables: hash_including(
          db: db_settings,
          password: /[a-f0-9]{32}/,
          db_server: db_server_info,
          environment: rails_env
        )
      )
    end

    it 'execute bundle install' do
      expect(chef_run).to run_bash("bundle_install_#{application_name}").with(
        cwd: "#{base_path}/#{application_name}/releases/#{app_version}",
        code: '/opt/rbenv/shims/bundle install --without test development --path=vendor/bundle'
      )
    end

    it 'execute db migration' do
      rails_env = 'production'
      chef_run.node.set['rails_part']['app']['rails_env'] = rails_env
      chef_run.converge(described_recipe)

      expect(chef_run).to run_bash("db_migrate_#{application_name}").with(
        cwd: "#{base_path}/#{application_name}/releases/#{app_version}",
        environment: {
          'RAILS_ENV' => rails_env,
          'RACK_ENV' => rails_env
        },
        code: '/opt/rbenv/shims/bundle exec rake db:migrate'
      )
    end

    it 'create a link to the application current' do
      expect(chef_run.link("#{base_path}/#{application_name}/current"))
        .to link_to("#{base_path}/#{application_name}/releases/#{app_version}")
    end

    it 'create init.d file of puma' do
      rails_env = 'production'
      chef_run.node.set['rails_part']['app']['rails_env'] = rails_env
      chef_run.converge(described_recipe)

      expect(chef_run).to create_template("/etc/init.d/#{application_name}").with(
        source: 'puma_init_script.erb',
        owner:  'root',
        group:  'root',
        mode:   '0755',
        variables: {
          app_name: application_name,
          app_path: "#{base_path}/#{application_name}",
          environment: rails_env
        }
      )
    end

    it 'restart puma service' do
      expect(chef_run).to restart_service(application_name)
    end

    it 'run post_deploy script' do
      command = 'pwd'
      chef_run.node.set['cloudconductor']['applications'][application_name]['post_deploy'] = command
      chef_run.converge(described_recipe)

      expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
        :bash,
        :run,
        "post_deploy_script_#{application_name}"
      ).with(
        code: command
      )
    end
  end

  describe 'multiple dynamic type applications are included in "cloudconductor applications"' do
    application_name_01 = 'foo'
    application_name_02 = 'bar'
    base_path = '/var/www'

    before do
      chef_run.node.set['cloudconductor']['applications'] = {
        application_name_01 => {
          type: 'dynamic',
          parameters: {}
        },
        application_name_02 => {
          type: 'dynamic',
          parameters: {}
        }
      }
      chef_run.node.set['rails_part']['app']['base_path'] = base_path
      chef_run.converge(described_recipe)
    end

    it 'create release directory for 1st application' do
      expect(chef_run).to create_directory("#{base_path}/#{application_name_01}/releases").with(
        recursive: true
      )
    end

    it 'create release directory for 2nd application' do
      expect(chef_run).to create_directory("#{base_path}/#{application_name_02}/releases").with(
        recursive: true
      )
    end
  end

  describe 'dynamic type applications are included in "cloudconductor applications"' do
    application_name = 'application_name'
    base_path = '/var/www'
    app_version = '0.3'

    before do
      chef_run.node.set['cloudconductor']['applications'] = {
        application_name => {
          type: 'static',
          version: app_version,
          parameters: {}
        }
      }
      chef_run.node.set['rails_part']['app']['base_path'] = base_path
      chef_run.converge(described_recipe)
    end

    it 'not create release directory' do
      expect(chef_run).to_not create_directory("#{base_path}/#{application_name}/releases").with(
        recursive: true
      )
    end
  end
end
