include_attribute 'yum-epel'
default['yum']['epel']['enabled'] = false

include_attribute 'serf'
default['serf']['agent']['bind'] = '0.0.0.0'
default['serf']['agent']['rpc_addr'] = '0.0.0.0:7373'
default['serf']['agent']['discover'] = 'cloudconductor'
default['serf']['agent']['enable_syslog'] = true
default['serf']['agent']['event-handler'] = ['/opt/cloudconductor/patterns/event-handler']

