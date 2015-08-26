# mysql Package install attribute
default['mysql']['version'] = '5.6'

default['mysql_part']['app']['database'] = 'application'
default['mysql_part']['app']['username'] = 'application'
default['mysql_part']['app']['encoding'] = 'utf8'
default['mysql_part']['app']['privileges'] = [:all]
default['mysql_part']['app']['require_ssl'] = false

default['mysql_part']['backup_directory'] = '/var/cloudconductor/backups/mysql'
