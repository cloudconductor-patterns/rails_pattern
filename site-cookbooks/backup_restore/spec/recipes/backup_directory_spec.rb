require_relative '../spec_helper'

describe 'backup_restore::backup_directory' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      cookbook_path: %w(site-cookbooks cookbooks),
      platform:      'centos',
      version:       '6.5'
    ).converge(described_recipe)
  end

  it 'run full backup' do
    log_dir = '/var/log/backup'
    user = 'root'
    expect(chef_run).to run_bash('run_full_backup').with(
      code: "backup perform --trigger directory --config-file /etc/backup/config.rb --log-path=#{log_dir}",
      user: "#{user}"
    )
  end
end
