name             'nginx_part'
version          '0.0.1'
description      'Install/Configure nginx'
license          'Apache v2.0'
maintainer       'TIS Inc.'
maintainer_email 'ccndctr@gmail.com'

supports 'centos', '= 6.5'

depends 'cloudconductor'
depends 'nginx'
depends 'nginx_conf'
