require_relative '../spec_helper'

describe 'backup_restore::configure_directory' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'create clon' do
    chef_run.node.set['cloudconductor']['applications']['app_name'] = {
      type: 'dynamic',
      parameters: {
        backup_directories: '/var/www/app'
      }
    }
    chef_run.node.set['backup_restore']['destinations']['s3'] = {
      bucket: 'cloudconductor',
      prefix: '/backup'
    }
    chef_run.node.set['backup_restore']['log_dir'] = '/var/log/backup'
    chef_run.converge(described_recipe)

    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :backup_model,
      :create,
      :directory
    ).with(
      description: 'Backup directories',
      definition: '`s3cmd sync /var/www/app s3://cloudconductor/backup/directories/`',
      cron_options: {
        path: ENV['PATH'],
        output_log: '/var/log/backup/backup.log'
      }
    )
  end

  it 'cron schedule is parsing the attirubte' do
    chef_run.node.set['backup_restore']['sources']['directory']['schedule'] = '0 2 * * 0'
    chef_run.converge(described_recipe)
    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :backup_model,
      :create,
      :directory
    ).with(
      schedule: {
        minute: '0',
        hour: '2',
        day: '*',
        month: '*',
        weekday: '0'
      }
    )
  end

  describe 'use proxy' do
    proxy_host = '127.0.0.250'
    proxy_port = '8080'

    before do
      chef_run.node.set['backup_restore']['config']['use_proxy'] = true
      chef_run.node.set['backup_restore']['config']['proxy_host'] = proxy_host
      chef_run.node.set['backup_restore']['config']['proxy_port'] = proxy_port
      chef_run.converge(described_recipe)
    end

    it 'write proxy settings to backup cron file' do
      expect(chef_run).to run_ruby_block('set_proxy_env')

      expect(Chef::Util::FileEdit).to receive(:new)
        .with('/etc/cron.d/directory_backup').and_return(Chef::Util::FileEdit.new(Tempfile.new('chefspec')))
      expect_any_instance_of(Chef::Util::FileEdit).to receive(:insert_line_after_match)
        .with(/# Crontab for/, "https_proxy=http://#{proxy_host}:#{proxy_port}/")
      expect_any_instance_of(Chef::Util::FileEdit).to receive(:insert_line_after_match)
        .with(/# Crontab for/, "http_proxy=http://#{proxy_host}:#{proxy_port}/")
      expect_any_instance_of(Chef::Util::FileEdit).to receive(:write_file)
      chef_run.ruby_block('set_proxy_env').old_run_action(:create)
    end
  end
end
