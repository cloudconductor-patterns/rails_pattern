require_relative '../spec_helper'

describe 'backup_restore::configure_directory' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      cookbook_path: %w(site-cookbooks cookbooks),
      platform:      'centos',
      version:       '6.5'
    ) do |node|
      node.set['cloudconductor']['applications'] = {
        dynamic_git_app: {
          type: 'dynamic',
          parameters: {
            backup_directories: '/var/www/app'
          }
        }
      }
      node.set['backup_restore']['config']['use_proxy'] = 'localhost'
      node.set['backup_restore']['destinations']['s3'] = {
        bucket: 'cloudconductor',
        access_key_id: '1234',
        secret_access_key: '4321',
        region: 'us-east-1',
        prefix: '/backup'
      }
    end
    runner.converge(described_recipe)
  end

  it 'create clon' do
    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :backup_model,
      :create,
      :directory
    ).with(
      description: 'Backup directories',
      definition: '`s3cmd sync /var/www/app s3://cloudconductor/backup/directories/`',
      schedule: {
        minute: '0',
        hour: '2',
        day: '*',
        month: '*',
        weekday: '0'
      },
      cron_options: {
        path: ENV['PATH'],
        output_log: '/var/log/backup/backup.log'
      }
    )
  end

  it 'set_proxy_env' do
    expect(chef_run).to run_ruby_block('set_proxy_env')
  end
end
