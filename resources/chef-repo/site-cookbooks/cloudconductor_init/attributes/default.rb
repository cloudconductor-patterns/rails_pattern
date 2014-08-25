include_attribute 'yum-epel'
default['yum']['epel']['enabled'] = false


include_attribute 'serf'
default['serf']['version'] = '0.6.3'
default['serf']['agent']['bind'] = '0.0.0.0'
default['serf']['agent']['rpc_addr'] = '0.0.0.0:7373'
default['serf']['agent']['enable_syslog'] = true
default['serf']['agent']['event_handlers'] = [ File.join(node['serf']['base_directory'], 'event_handlers', 'event-handler') ]
default['serf']['agent']['tags']['role'] = node['serf']['agent']['tags']['role']
default['serf']['user'] = 'root'
default['serf']['group'] = 'root'

