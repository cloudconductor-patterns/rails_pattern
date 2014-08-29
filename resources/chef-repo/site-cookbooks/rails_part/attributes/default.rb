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
  },
  app: {
    name:       'app',
    path:       '/var/www/app',
    repository: 'http://172.0.0.1/app.git',
    revision:   'HEAD',
    migrate:    true,
    migration_command: '/opt/rbenv/shims/bundle exec rake db:migrate',
    rails_env:  'production',
    bundler:    true,
    bundle_command: '/opt/rbenv/shims/bundle',
  },
  db: {
    adapter:  'mysql2',
    host:     'localhost',
    database: 'database',
    user:     'dbuser',
    password: 'ilikerandompassword'
  },
  puma: {
    bind:          'tcp://0.0.0.0:9292',
    output_append: true,
    logrotate:     false,
    thread_min:    '0',
    thread_max:    '16',
    workers:       '2'
  },
  pre_script: 'echo start deploy',
  post_script: 'echo finish deploy'
}
