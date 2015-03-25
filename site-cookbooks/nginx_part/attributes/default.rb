default['nginx_part']['tmp_dir'] = '/tmp/nginx'

# 'nginx' attributes
include_attribute 'nginx'
default['nginx']['repo_source'] = 'nginx'
default['nginx']['default_site_enabled'] = false

include_attribute 'nginx_conf'
default['nginx_conf']['locations'] = {}

# 'cloudconductor' attributes
# include_attribute 'cloudconductor'
default['cloudconductor']['applications'] = {}
