#
default['create_user']['host']          = 'localhost'
default['create_user']['username']      = 'root'
default['create_user']['password']      = 'ilikerandompasswords'
default['create_user']['new_username']  = 'appuser'
default['create_user']['new_password']  = 'ilikerandompasswords'
default['create_user']['database_name'] = 'app'
default['create_user']['privileges']    = [
  :select,
  :update,
  :insert
]
default['create_user']['reuire_ssl']    = 'ture'

