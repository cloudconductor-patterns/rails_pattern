::Chef::Recipe.send(:include, BackupRubyHelper)
::Chef::Resource.send(:include, BackupRubyHelper)

backup_model :ruby_full do
  s3_dst = node['backup_restore']['destinations']['s3']

  description 'Full Backup ruby application with gems'
  definition lazy { <<-DEF
    split_into_chunks_of 4000

    archive :ruby do |archive|
      archive.root '#{node['rails_part']['app']['base_path']}'
      #{application_paths}
      archive.tar_options '--xattrs --warning=no-file-removed --warning=no-file-changed'
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
  }

  schedule(parse_schedule(node['backup_restore']['sources']['ruby']['schedule']['full']))
  cron_options(
    path: ENV['PATH'],
    output_log: "#{node['backup_restore']['log_dir']}/backup_ruby.log"
  )
end

# set proxy environment if use_proxy
if node['backup_restore']['config']['use_proxy']
  ruby_block 'set_proxy_env' do
    block do
      proxy_url = "http://#{node['backup_restore']['config']['proxy_host']}:#{node['backup_restore']['config']['proxy_port']}/"
      cron_file = '/etc/cron.d/ruby_full_backup'
      file = Chef::Util::FileEdit.new(cron_file)
      file.insert_line_after_match(/# Crontab for/, "https_proxy=#{proxy_url}")
      file.insert_line_after_match(/# Crontab for/, "http_proxy=#{proxy_url}")
      file.write_file
      File.delete("#{cron_file}.old") if File.exist?("#{cron_file}.old")
    end
  end
end
