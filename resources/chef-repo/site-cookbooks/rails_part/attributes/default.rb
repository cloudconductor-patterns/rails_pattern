default['rails_part'] = {
  ruby: {
    version: '2.1.1',
    global:  true
  },
  user: {
    name:        'rails',
    passwd:      '$1$ID1d8IuR$oyeSAB1Z5gHptbJimJ8Fr/',
    manage_home: true,
    group:       'rails'
  }
}
default['deploy_rails_puma']['app_name'] = 'app'
default['deploy_rails_puma']['app_path'] = '/var/www/app'
default['deploy_rails_puma']['app_user'] = 'rails'
default['deploy_rails_puma']['app_group'] = 'rails'

default['deploy_rails_puma']['deploy']['repository'] = 'http://172.0.0.1/app.git'
default['deploy_rails_puma']['deploy']['revision'] = 'HEAD'
default['deploy_rails_puma']['deploy']['migrate'] = true
default['deploy_rails_puma']['deploy']['migration_command'] = '/opt/rbenv/shims/bundle exec rake db:migrate'
default['deploy_rails_puma']['deploy']['rails_env'] = 'production'

default['deploy_rails_puma']['rails']['bundler'] = true
default['deploy_rails_puma']['rails']['bundle_command'] = '/opt/rbenv/shims/bundle'

default['deploy_rails_puma']['db']['adapter'] = 'mysql2'
default['deploy_rails_puma']['db']['host'] = 'localhost'
default['deploy_rails_puma']['db']['database'] = 'database'
default['deploy_rails_puma']['db']['user'] = 'dbuser'
default['deploy_rails_puma']['db']['password'] = 'ilikerandompassword'

default['deploy_rails_puma']['puma']['bind'] = 'tcp://0.0.0.0:9292'
default['deploy_rails_puma']['puma']['output_append'] = true
default['deploy_rails_puma']['puma']['logrotate'] = false
default['deploy_rails_puma']['puma']['thread_min'] = '0'
default['deploy_rails_puma']['puma']['thread_max'] = '16'
default['deploy_rails_puma']['puma']['workers'] = '2'
default['deploy_rails_puma']['puma']['rails_environment'] = 'production'
