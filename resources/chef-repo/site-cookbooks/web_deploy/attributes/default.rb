# Create Directory
default['web_deploy']['default_root'] = '/var/www'
default['web_deploy']['owner']        = 'root'
default['web_deploy']['group']        = 'root'
default['web_deploy']['mode']         = '00775'

# application download
default['web_deploy']['app_path']   = '/var/www/bousaiz'
default['web_deploy']['repository'] = 'http://172.0.0.1/application/app.git'
default['web_deploy']['revision']    = 'master'

# create config
default['web_deploy']['app_conf_path'] = '/etc/nginx/conf.d'
default['web_deploy']['app_conf_name'] = 'test.conf'

# create template
default['app']['name']   = 'app'
default['app']['host']   = '0.0.0.0'
default['app']['port']   = '8080'
default['app']['index']  = 'index.html'
default['app']['log']    = '/var/log/nginx/log'
default['app']['url']    = '/'

default['nginx']['port'] = '80'
default['nginx']['host'] = '0.0.0.0'
default['nginx']['url']  = '/static'
default['nginx']['root'] = '/var/www/app'
