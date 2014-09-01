include_attribute 'nginx'
# nginx_part::setup default_attribute
# install nginx:repo
force_default['nginx']['repo_source'] = 'nginx'

# nginx_part::deploy default_attribute
# Create Directory
default['nginx_part']['static_root'] = '/var/www'
default['nginx_part']['static_owner'] = 'root'
default['nginx_part']['static_group'] = 'root'
default['nginx_part']['static_mode'] = '0775'

# application download
default['cloudconductor']['application_url'] = 'http://172.0.0.1/application/app.git'
default['cloudconductor']['application_revision'] = 'master'

# create config
default['nginx_part']['conf_path'] = '/etc/nginx'

# create upstream config
default['nginx_part']['upstream_conf_name'] = 'upstream.conf'

# create application config
default['nginx_part']['app_name'] = 'app'
default['nginx_part']['app_conf_name'] = 'app.conf'
default['nginx_part']['app_log_dir'] = '/var/log/nginx/log'

# create template
default['cloudconductor']['ap_host'] = '0.0.0.0'
default['nginx_part']['ap_svr_port'] = '8080'
default['nginx_part']['ap_svr_url_path'] = '/'
default['nginx_part']['ap_svr_index'] = 'index.html'

default['nginx_part']['web_svr_port'] = '80'
default['nginx_part']['web_svr_host'] = '0.0.0.0'
default['nginx_part']['web_svr_url_path'] = '/static'
default['nginx_part']['web_svr_index'] = 'index.html'

# create log directory
default['nginx_part']['log_owner'] = 'nginx'
default['nginx_part']['log_group'] = 'nginx'
default['nginx_part']['log_mode'] = '0775'
