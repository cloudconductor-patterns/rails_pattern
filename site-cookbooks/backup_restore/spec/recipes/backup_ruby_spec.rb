require_relative '../spec_helper'

describe 'backup_restore::backup_ruby' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  it 'run a full backup' do
    user = 'root'
    log_dir = '/var/log/backup'
    chef_run.node.set['backup_restore']['user'] = user
    chef_run.node.set['backup_restore']['log_dir'] = log_dir
    chef_run.converge(described_recipe)

    expect(chef_run).to run_bash('run_full_backup').with(
      code: "backup perform --trigger ruby_full --config-file /etc/backup/config.rb --log-path=#{log_dir}",
      user: "#{user}"
    )
  end
end
