::Chef::Recipe.send(:include, BackupDirectoryHelper)
::Chef::Resource.send(:include, BackupDirectoryHelper)

source = node['backup_restore']['sources']['directory']

backup_model :directory do
  description 'Backup directories'
  definition syncer_definition
  schedule parse_schedule
  cron_options(
    path: ENV['PATH'],
    output_log: "#{node['backup_restore']['log_dir']}/backup.log"
  )
end

# set proxy environment if use_proxy
if node['backup_restore']['config']['use_proxy']
  ruby_block 'set_proxy_env' do
    block do
      proxy_url = "http://#{node['backup_restore']['config']['proxy_host']}:#{node['backup_restore']['config']['proxy_port']}/"

      cron_file = "/etc/cron.d/directory_backup"
      file = Chef::Util::FileEdit.new(cron_file)
      file.insert_line_after_match(/# Crontab for/, "https_proxy=#{proxy_url}")
      file.insert_line_after_match(/# Crontab for/, "http_proxy=#{proxy_url}")
      file.write_file
      File.delete("#{cron_file}.old") if File.exist?("#{cron_file}.old")
    end
  end
end
