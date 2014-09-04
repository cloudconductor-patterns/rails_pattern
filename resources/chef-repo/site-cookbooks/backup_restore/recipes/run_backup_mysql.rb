bash 'run_full_backup' do
  code "backup perform --trigger mysql_full --config-file /etc/backup/config.rb --log-path=#{node['backup_restore']['log_dir']}"
  user node['backup_restore']['user']
end
