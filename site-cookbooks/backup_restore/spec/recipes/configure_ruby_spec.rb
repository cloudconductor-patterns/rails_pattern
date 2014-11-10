require_relative '../spec_helper'

describe 'backup_restore::configure_ruby' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'create clon' do
    chef_run.node.set['backup_restore']['log_dir'] = '/var/log/backup'
    chef_run.converge(described_recipe)

    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :backup_model,
      :create,
      :ruby_full
    ).with(
      description: 'Full Backup ruby application with gems',
      cron_options: {
        path: ENV['PATH'],
        output_log: '/var/log/backup/backup_ruby.log'
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

      expect(Chef::Util::FileEdit).to receive(:new).with('/etc/cron.d/ruby_full_backup')
        .and_return(Chef::Util::FileEdit.new(Tempfile.new('chefspec')))
      expect_any_instance_of(Chef::Util::FileEdit).to receive(:insert_line_after_match)
        .with(/# Crontab for/, "https_proxy=http://#{proxy_host}:#{proxy_port}/")
      expect_any_instance_of(Chef::Util::FileEdit).to receive(:insert_line_after_match)
        .with(/# Crontab for/, "http_proxy=http://#{proxy_host}:#{proxy_port}/")
      expect_any_instance_of(Chef::Util::FileEdit).to receive(:write_file)
      chef_run.ruby_block('set_proxy_env').old_run_action(:create)
    end
  end

  it 'cron schedule is parsing the attirubte' do
    chef_run.node.set['backup_restore']['sources']['ruby']['schedule']['full'] = '0 2 * * 0'
    chef_run.converge(described_recipe)
    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :backup_model,
      :create,
      :ruby_full
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
end
