tmp_dir = "#{node['backup_restore']['tmp_dir']}/restore"
source = node['backup_restore']['sources']['mysql']
full_backup_name = "mysql_full"
incremental_backup_name = "mysql_incremental"

bash 'extract_full_backup' do
  code <<-EOF
    tar -xvf #{tmp_dir}/#{full_backup_name}.tar -C #{tmp_dir}
    tar -zxvf #{tmp_dir}/#{full_backup_name}/databases/MySQL.tar.gz -C #{tmp_dir}/#{full_backup_name}
  EOF
  not_if { ::Dir.exist?("#{tmp_dir}/#{full_backup_name}") }
end

bash 'extract_and_apply_incremental_backup' do
  code <<-EOF
    incremental_backups=(`find #{tmp_dir}/#{incremental_backup_name} -mindepth 1 -maxdepth 1`)
    for incremental_backup in ${incremental_backups[@]}
    do
      if [ ! -d ${incremental_backup}/MySQL.bkpdir ]; then
        tar -xvf ${incremental_backup}/#{incremental_backup_name}.tar -C ${incremental_backup}
        tar -zxvf ${incremental_backup}/#{incremental_backup_name}/databases/MySQL.tar.gz -C ${incremental_backup}
        innobackupex --apply-log --redo-only #{tmp_dir}/#{full_backup_name}/MySQL.bkpdir \
          --incremental-dir ${incremental_backup}/MySQL.bkpdir
      fi
    done
  EOF
  only_if { ::Dir.exist?("#{tmp_dir}/#{incremental_backup_name}") }
end

service 'mysqld' do
  action :stop
end

bash 'delete_old_data' do
  code "rm -rf #{source['data_dir']}/*"
  not_if { ::Dir["#{source['data_dir']}/*"].empty? }
end

bash 'restore_backup' do
  code <<-EOF
    innobackupex --copy-back #{tmp_dir}/#{full_backup_name}/MySQL.bkpdir
    chown -R #{source['run_user']}:#{source['run_group']} #{source['data_dir']}
  EOF
  only_if { ::Dir.exist?("#{tmp_dir}/#{full_backup_name}/MySQL.bkpdir") }
end

service 'mysqld' do
  action :start
end
