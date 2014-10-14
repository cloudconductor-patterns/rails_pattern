# mysql Package install attribute
default['mysql']['version'] = '5.6'

default['mysql_part']['app']['database'] = 'rails'
default['mysql_part']['app']['username'] = 'rails'
default['mysql_part']['app']['password'] = 'todo_replace_randompassword'
default['mysql_part']['app']['encoding'] = 'utf8'
default['mysql_part']['app']['privileges'] = [:all]
default['mysql_part']['app']['require_ssl'] = false
