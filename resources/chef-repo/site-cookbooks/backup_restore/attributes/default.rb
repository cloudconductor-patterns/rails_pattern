# backup configurations
default['backup_restore']['tmp_dir'] = '/tmp/backup'
default['backup_restore']['log_dir'] = '/var/log/backup'
default['backup_restore']['user'] = 'root'
default['backup_restore']['group'] = node['backup_restore']['user']
default['backup_restore']['home'] = '/root'
default['backup_restore']['config']['use_proxy'] = false
default['backup_restore']['config']['proxy_host'] = ''
default['backup_restore']['config']['proxy_port'] = ''
# backup sources
default['backup_restore']['sources']['enabled'] = []
default['backup_restore']['sources']['mysql']['db_user'] = 'root'
default['backup_restore']['sources']['mysql']['db_password'] = ''
default['backup_restore']['sources']['mysql']['data_dir'] = '/var/lib/mysql'
default['backup_restore']['sources']['mysql']['run_user'] = 'mysql'
default['backup_restore']['sources']['mysql']['run_group'] = 'mysql'
default['backup_restore']['sources']['mysql']['schedule']['full'] = "0 2 * * 0"
default['backup_restore']['sources']['mysql']['schedule']['incremental'] = "0 2 * * 1-6"
# backup destinations
default['backup_restore']['destinations']['enabled'] = []
default['backup_restore']['destinations']['s3']['bucket'] = ''
default['backup_restore']['destinations']['s3']['access_key_id'] = ''
default['backup_restore']['destinations']['s3']['secret_access_key'] = ''
default['backup_restore']['destinations']['s3']['region'] = 'us-east-1'
default['backup_restore']['destinations']['s3']['prefix'] = '/backup'
# restore target (e.g. ['mysql'])
default['backup_restore']['restore']['target_sources'] = []

# override dependent cookbooks attributes
# 'backup'
default['backup']['version_from_git?'] = true
default['backup']['git_repo'] = 'https://github.com/meskyanichi/backup'
default['backup']['dependencies'] = %w(fog s3)
# 'percona'
default['percona']['skip_passwords'] = true
# 's3cmd-master'
default['s3cmd']['user'] = node['backup_restore']['user']
default['s3cmd']['group'] = node['backup_restore']['group']
default['s3cmd']['home'] = node['backup_restore']['home']
