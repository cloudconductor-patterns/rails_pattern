# Create Directory
default['web_deploy']['default_root'] = '/var/www'
default['web_deploy']['owner']        = 'root'
default['web_deploy']['group']        = 'root'
default['web_deploy']['mode']         = '0775'

# application download
default['web_deploy']['app_path']   = '/var/www/app'
default['web_deploy']['repository'] = 'http://172.0.0.1/application/app.git'
default['web_deploy']['revision']    = 'master'

# create config
default['web_deploy']['app_conf_path'] = '/etc/nginx/conf.d'
default['web_deploy']['app_conf_name'] = 'app.conf'

# create template
default['nginx_app']['name']   = 'app'
default['nginx_app']['host']   = '0.0.0.0'
default['nginx_app']['port']   = '8080'
default['nginx_app']['index']  = 'index.html'
default['nginx_app']['log']    = '/var/log/nginx/log'
default['nginx_app']['url']    = '/'

default['nginx']['port'] = '80'
default['nginx']['host'] = '0.0.0.0'
default['nginx']['url']  = '/static'
default['nginx']['root'] = '/var/www/app'

# create log directory
default['nginx_log']['owner'] = 'nginx'
default['nginx_log']['group'] = 'nginx'
default['nginx_log']['mode'] = '0775'
