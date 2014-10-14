name 'nginx_part'
description 'Installs/Configures nginx'
maintainer 'TIS.inc'
maintainer_email 'ccndctr@gmail.com'
license 'Apache 2.0'
version '0.0.1'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))

depends 'cloudconductor'
depends 'nginx'
depends 'nginx_conf'
