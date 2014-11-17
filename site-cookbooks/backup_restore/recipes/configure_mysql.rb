::Chef::Recipe.send(:include, BackupMySQLHelper)
::Chef::Resource.send(:include, BackupMySQLHelper)

source = node['backup_restore']['sources']['mysql']

directory lsn_dir do
  recursive true
  action :create
end

# configure full backup
backup_model :mysql_full do
  description 'Full Backup MySQL database'
  definition <<-DEF
    split_into_chunks_of 4000

    database MySQL do |db|
      db.backup_engine = :innobackupex
      db.name = :all
      db.username = "#{source['db_user']}"
      db.password = "#{source['db_password']}"
      db.additional_options = ["--extra-lsndir #{lsn_dir}"]
      db.prepare_options = ["--redo-only"]
    end

    compress_with Gzip

    #{import_stores}

    after do |exit_status|
      if exit_status <= 1
        model = Backup::Model.find_by_trigger(:mysql_full).first
        s3_storage = model.storages.find { |storage| storage.send(:storage_name) == "Storage::S3" }
        File.write("#{latest_full_backup}", s3_storage.send(:remote_path))
      end
    end
  DEF
  schedule(parse_schedule(node['backup_restore']['sources']['mysql']['schedule']['full']))
  cron_options(
    path: ENV['PATH'],
    output_log: "#{node['backup_restore']['log_dir']}/backup.log"
  )
  only_if { source['schedule']['full'] && !source['schedule']['full'].empty? }
end

# configure incremental backup
backup_model :mysql_incremental do
  description 'Incremental Backup MySQL database'
  definition <<-DEF
    split_into_chunks_of 4000

    before do
      fail 'Cannot found latest full backup path' unless File.exists?("#{latest_full_backup}")
    end

    database MySQL do |db|
      db.backup_engine = :innobackupex
      db.name = :all
      db.username = "#{source['db_user']}"
      db.password = "#{source['db_password']}"
      db.additional_options = ["--incremental", "--incremental-basedir #{lsn_dir}", "--extra-lsndir #{lsn_dir}"]
      db.prepare_options = ["--version"]
    end

    compress_with Gzip

    #{import_stores(incremental: true)}
  DEF
  schedule(parse_schedule(node['backup_restore']['sources']['mysql']['schedule']['incremental']))
  cron_options(
    path: ENV['PATH'],
    output_log: "#{node['backup_restore']['log_dir']}/backup.log"
  )
  only_if { source['schedule']['incremental'] && !source['schedule']['incremental'].empty? }
end

# set proxy environment if use_proxy
ruby_block 'set_proxy_env' do
  block do
    proxy_url = "http://#{node['backup_restore']['config']['proxy_host']}:#{node['backup_restore']['config']['proxy_port']}/"
    schedules = []
    schedules << 'full' if source['schedule']['full'] && !source['schedule']['full'].empty?
    schedules << 'incremental' if source['schedule']['incremental'] && !source['schedule']['incremental'].empty?
    schedules.each do |type|
      cron_file = "/etc/cron.d/mysql_#{type}_backup"
      file = Chef::Util::FileEdit.new(cron_file)
      file.insert_line_after_match(/# Crontab for/, "https_proxy=#{proxy_url}")
      file.insert_line_after_match(/# Crontab for/, "http_proxy=#{proxy_url}")
      file.write_file
      File.delete("#{cron_file}.old") if File.exist?("#{cron_file}.old")
    end
  end
  only_if { node['backup_restore']['config']['use_proxy'] }
end
