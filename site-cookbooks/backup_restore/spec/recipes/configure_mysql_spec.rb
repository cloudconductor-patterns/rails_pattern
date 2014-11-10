require_relative '../spec_helper'

describe 'backup_restore::configure_mysql' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'creaet lsn directory' do
    expect(chef_run).to create_directory('/tmp/backup/mysql/lsn_dir').with(
      recursive: true
    )
  end

  describe 'full backup skedule is set' do
    it 'create clon full backup' do
      chef_run.node.set['backup_restore']['sources']['mysql']['schedule']['full'] = '0 2 * * 0'
      chef_run.converge(described_recipe)

      expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
        :backup_model,
        :create,
        :mysql_full
      ).with(
        description: 'Full Backup MySQL database',
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
  end

  describe 'incremental backup skedule is set' do
    it 'create clon incremental backup' do
      chef_run.node.set['backup_restore']['sources']['mysql']['schedule']['incremental'] = '0 2 * * 1-6'
      chef_run.converge(described_recipe)

      expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
        :backup_model,
        :create,
        :mysql_incremental
      ).with(
        description: 'Incremental Backup MySQL database',
        schedule: {
          minute: '0',
          hour: '2',
          day: '*',
          month: '*',
          weekday: '1-6'
        },
        cron_options: {
          path: ENV['PATH'],
          output_log: '/var/log/backup/backup.log'
        }
      )
    end
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

    describe 'full backup schedule is set' do
      it 'write proxy settings to full backup cron file' do
        chef_run.node.set['backup_restore']['sources']['mysql']['schedule']['full'] = '0 2 * * 0'
        chef_run.node.set['backup_restore']['sources']['mysql']['schedule']['incremental'] = ''
        chef_run.converge(described_recipe)

        expect(chef_run).to run_ruby_block('set_proxy_env')

        allow(Chef::Util::FileEdit).to receive(:new).and_return(Chef::Util::FileEdit.new(Tempfile.new('chefspec')))
        expect(Chef::Util::FileEdit).to receive(:new)
          .with('/etc/cron.d/mysql_full_backup').and_return(Chef::Util::FileEdit.new(Tempfile.new('chefspec')))
        expect_any_instance_of(Chef::Util::FileEdit).to receive(:insert_line_after_match)
          .with(/# Crontab for/, "https_proxy=http://#{proxy_host}:#{proxy_port}/")
        expect_any_instance_of(Chef::Util::FileEdit).to receive(:insert_line_after_match)
          .with(/# Crontab for/, "http_proxy=http://#{proxy_host}:#{proxy_port}/")
        expect_any_instance_of(Chef::Util::FileEdit).to receive(:write_file)
        chef_run.ruby_block('set_proxy_env').old_run_action(:create)
      end
    end

    describe 'incremental backup schedule is set' do
      it 'write proxy settings to full backup cron file' do
        chef_run.node.set['backup_restore']['sources']['mysql']['schedule']['full'] = ''
        chef_run.node.set['backup_restore']['sources']['mysql']['schedule']['incremental'] = '0 2 * * 1-6'
        chef_run.converge(described_recipe)

        expect(chef_run).to run_ruby_block('set_proxy_env')

        expect(Chef::Util::FileEdit).to receive(:new)
          .with('/etc/cron.d/mysql_incremental_backup').and_return(Chef::Util::FileEdit.new(Tempfile.new('chefspec')))
        expect_any_instance_of(Chef::Util::FileEdit).to receive(:insert_line_after_match)
          .with(/# Crontab for/, "https_proxy=http://#{proxy_host}:#{proxy_port}/")
        expect_any_instance_of(Chef::Util::FileEdit).to receive(:insert_line_after_match)
          .with(/# Crontab for/, "http_proxy=http://#{proxy_host}:#{proxy_port}/")
        expect_any_instance_of(Chef::Util::FileEdit).to receive(:write_file)
        chef_run.ruby_block('set_proxy_env').old_run_action(:create)
      end
    end
  end
end
