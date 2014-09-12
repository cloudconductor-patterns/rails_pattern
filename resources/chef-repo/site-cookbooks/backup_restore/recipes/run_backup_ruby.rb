::Chef::Recipe.send(:include, BackupRubyHelper)
::Chef::Resource.send(:include, BackupRubyHelper)

backup_model :ruby_full do
  s3_dst = node['backup_restore']['destinations']['s3']

  description 'Full Backup ruby application with gems'
  definition <<-DEF
    split_into_chunks_of 4000

    archive :ruby do |archive|
      #{application_paths}
      archive.tar_options '-h --xattrs'
    end

    compress_with Gzip

    store_with S3 do |s3|
      s3.bucket = "#{s3_dst['bucket']}"
      s3.region = "#{s3_dst['region']}"
      s3.access_key_id = "#{s3_dst['access_key_id']}"
      s3.secret_access_key = "#{s3_dst['secret_access_key']}"
      s3.path = "#{s3_dst['prefix']}"
      s3.max_retries = 2
      s3.retry_waitsec = 10
    end
  DEF
end

bash 'run_full_backup' do
  code "backup perform --trigger ruby_full --config-file /etc/backup/config.rb --log-path=#{node['backup_restore']['log_dir']}"
  user node['backup_restore']['user']
end
