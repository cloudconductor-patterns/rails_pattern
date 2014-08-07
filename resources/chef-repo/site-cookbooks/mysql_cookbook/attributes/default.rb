# include attribute

include_attribute "mysql::default"

# default setting
default['mysql']['hostname'] = 'localhost'
default['mysql']['user'] = 'root'

# Change Setting
default['mysql']['new_root_password'] = 'qawsedrftgyhujikolp'

