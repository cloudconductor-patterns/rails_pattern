default['nginx_part']['tmp_dir'] = '/tmp/nginx'

# 'nginx' attributes
include_attribute 'nginx'
default['nginx']['repo_source'] = 'nginx'
default['nginx']['default_site_enabled'] = false

# 'cloudconductor' attributes
# include_attribute 'cloudconductor'
default['cloudconductor']['applications'] = []
default['cloudconductor']['ap_host'] = '127.0.0.1'
