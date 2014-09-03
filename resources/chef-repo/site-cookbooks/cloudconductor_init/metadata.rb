name             'cloudconductor_init'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures cloudconductor_init'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends          'yum-epel', '~> 0.4.0'
depends          'serf', '~> 0.7.0'
depends          'consul', '~> 0.3.0'
depends          'iptables'
