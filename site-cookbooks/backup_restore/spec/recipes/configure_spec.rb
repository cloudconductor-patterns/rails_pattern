require_relative '../spec_helper'

describe 'backup_restore::configure' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'create log directory' do
    expect(chef_run).to create_directory('/var/log/backup').with(
      owner: 'root',
      group: 'root'
    )
  end

  describe 'contains s3 to a enabled destinations' do
    before do
      chef_run.node.set['backup_restore']['destinations']['enabled'] = %w(s3)
      chef_run.node.set['backup_restore']['destinations']['s3'] = {
        bucket: 's3bucket',
        access_key_id: 'access_key_id',
        secret_access_key: 'secret_access_key',
        region: 'us-east-1',
        prefix: '/backup'
      }
      chef_run.converge(described_recipe)
    end

    it 'create s3 config' do
      expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
        :s3cfg,
        :create,
        '/root/.s3cfg'
      ).with(
        access_key: 'access_key_id',
        secret_key: 'secret_access_key',
        owner: 'root',
        group: 'root',
        install_s3cmd: false
      )
    end

    describe 'use proxy' do
      it 'create s3 config include proxy settings' do
        chef_run.node.set['backup_restore']['config']['use_proxy'] = true
        chef_run.node.set['backup_restore']['config']['proxy_host'] = '127.0.0.250'
        chef_run.node.set['backup_restore']['config']['proxy_port'] = '8080'
        chef_run.converge(described_recipe)
        expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
          :s3cfg,
          :create,
          '/root/.s3cfg'
        ).with(
          config: {
            'proxy_host' => '127.0.0.250',
            'proxy_port' => '8080',
            'use_https' => false
          }
        )
      end
    end
    describe 'not use proxy' do
      it 'create s3 config include proxy settings' do
        chef_run.node.set['backup_restore']['config']['use_proxy'] = false
        chef_run.converge(described_recipe)
        expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
          :s3cfg,
          :create,
          '/root/.s3cfg'
        ).with(
          config: {}
        )
      end
    end
  end

  describe 'contains diractory to a enabled sources' do
    it 'include mysql configure recipe' do
      chef_run.node.set['backup_restore']['sources']['enabled'] = %w(directory)
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('backup_restore::configure_directory')
    end
  end

  describe 'contains mysql to a enabled sources' do
    it 'include mysql configure recipe' do
      chef_run.node.set['backup_restore']['sources']['enabled'] = %w(mysql)
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('backup_restore::configure_mysql')
    end
  end

  describe 'contains ruby to a enabled sources' do
    it 'include mysql configure recipe' do
      chef_run.node.set['backup_restore']['sources']['enabled'] = %w(ruby)
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('backup_restore::configure_ruby')
    end
  end
end
