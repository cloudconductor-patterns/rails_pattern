require_relative '../spec_helper'

describe 'backup_restore::restore_directory' do
  let(:chef_run) do
    runner = ChefSpec::Runner.new(
      cookbook_path: %w(site-cookbooks cookbooks),
      platform:      'centos',
      version:       '6.5'
    ) do |node|
      node.set['cloudconductor']['applications'] = {
        dynamic_git_app: {
          type: 'dynamic',
          #protocol: 'git',
          #url: 'http://github.com/foo.git',
          #pre_deploy: 'date',
          #post_deploy: 'ifconfig',
          parameters: {
          #  port: '8080'
            backup_directories: '/var/www/app' 
          }
        } 
      }
      node.set['backup_restore']['destinations']['s3'] = {
        bucket: 'cloudconductor',
        access_key_id: '1234',
        secret_access_key: '4321',
        region: 'us-east-1',
        prefix: '/backup',
      }
    end
    runner.converge(described_recipe)
  end

  it 'create backup directory' do
    expect(chef_run).to create_directory('/var/www/app').with(
      recursive: true
    )
  end
end
