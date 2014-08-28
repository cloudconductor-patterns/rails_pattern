# Find highest priority backup
s3 = node['backup_restore']['destinations']['s3']
tmp_dir = "#{node['backup_restore']['tmp_dir']}/restore"

node['backup_restore']['restore']['target_sources'].each do |source_type|
  # Find latest backup on S3
  source = node['backup_restore']['sources'][source_type]
  backup_name = "#{source_type}_full"
  s3_path = "s3://#{s3['bucket']}#{s3['prefix']}/#{backup_name}/"
  datetime_regexp = '[0-9]\{4\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}.[0-9]\{2\}/$'
  cmd = "/usr/bin/s3cmd ls #{s3_path} | grep '#{datetime_regexp}' | sort | awk 'END{print $2}'"
  latest_backup_path = `#{cmd}`.chomp

  # Download backup from S3
  bash 'download_backup_files' do
    code "/usr/bin/s3cmd get -r #{latest_backup_path} #{tmp_dir}"
    not_if { ::File.exist?("#{tmp_dir}/#{backup_name}.tar") }
  end
end
