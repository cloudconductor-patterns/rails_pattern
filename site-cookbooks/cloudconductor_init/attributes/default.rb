# override yum-epel attributes
default['yum']['epel']['enabled'] = false

# override serf attributes
default['serf']['version'] = '0.6.3'
default['serf']['agent']['bind'] = '0.0.0.0'
default['serf']['agent']['rpc_addr'] = '0.0.0.0:7373'
default['serf']['agent']['enable_syslog'] = true
default['serf']['agent']['event_handlers'] = [ File.join(node['serf']['base_directory'], 'event_handlers', 'event-handler') ]
default['serf']['user'] = 'root'
default['serf']['group'] = 'root'

# override consul attributes
default['consul']['service_mode'] = 'server'
default['consul']['service_user'] = 'root'
default['consul']['service_group'] = 'root'
default['consul']['bind_addr'] = '0.0.0.0'
