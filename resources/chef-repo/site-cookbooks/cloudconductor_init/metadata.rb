name             'cloudconductor_init'
version          '0.0.1'
description      'Installs/Configures cloudconductor_init'
license          'Apache v2.0'
maintainer       'TIS Inc.'
maintainer_email 'ccndctr@gmail.com'
supports         'centos', '= 6.5'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

depends          'iptables'
depends          'yum-epel'
depends          'serf', '>= 0.7.0'
depends          'consul', '>= 0.3.0'
