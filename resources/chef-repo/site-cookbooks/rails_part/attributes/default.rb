default['cloudconductor']['applications'] = []
default['cloudconductor']['ap_host'] = '127.0.0.1'
default['cloudconductor']['db_host'] = '127.0.0.1'

default['rails_part']['ruby']['version'] = '2.1.2'
default['rails_part']['ruby']['global'] = true

default['rails_part']['user']['name'] = 'rails'
default['rails_part']['user']['group'] = node['rails_part']['user']['name']
default['rails_part']['user']['passwd'] = [*1..9, *'A'..'Z', *'a'..'z'].sample(8).join
default['rails_part']['user']['manage_home'] = true

default['rails_part']['app']['base_path'] = '/var/www'
default['rails_part']['app']['migrate'] = true
default['rails_part']['app']['migration_command'] = '/opt/rbenv/shims/bundle exec rake db:migrate'
default['rails_part']['app']['rails_env'] = 'production'
default['rails_part']['app']['bundler'] = true
default['rails_part']['app']['bundle_command'] = '/opt/rbenv/shims/bundle'

default['rails_part']['db']['adapter'] = 'mysql2'
default['rails_part']['db']['database'] = 'rails'
default['rails_part']['db']['host'] = node['cloudconductor']['db_host']
default['rails_part']['db']['user'] = 'rails'
default['rails_part']['db']['password'] = 'todo_replace_randompassword'

default['rails_part']['puma']['bind'] = 'tcp://0.0.0.0:8080'
default['rails_part']['puma']['output_append'] = true
default['rails_part']['puma']['logrotate'] = false
default['rails_part']['puma']['thread_min'] = 0
default['rails_part']['puma']['thread_max'] = 16
default['rails_part']['puma']['workers'] = 2
