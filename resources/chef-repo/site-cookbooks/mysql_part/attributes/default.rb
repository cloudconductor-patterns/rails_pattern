# mysql Package install attribute
include_attribute 'mysql'
force_default['mysql']['version'] = '5.6'

# create user attribute
default['mysql_part']['host'] = 'localhost'
default['mysql_part']['username'] = 'root'
default['mysql_part']['password'] = 'ilikerandompasswords'
default['mysql_part']['new_username'] = 'appuser'
default['mysql_part']['new_password'] = 'ilikerandompasswords'
default['mysql_part']['database_name'] = 'app'
default['mysql_part']['privileges'] = [:select, :update, :insert, :delete]
default['mysql_part']['require_ssl'] = 'ture'

# create database attribute
default['mysql_part']['encoding'] = 'utf8'
