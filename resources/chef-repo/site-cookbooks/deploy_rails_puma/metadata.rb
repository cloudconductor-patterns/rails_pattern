name             'deploy_rails_puma'
maintainer       'YOUR_COMPANY_NAME'
maintainer_email 'YOUR_EMAIL'
license          'All rights reserved'
description      'Installs/Configures deploy_rails_puma'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

depends 'application'
depends 'application_ruby'
depends 'rbenv'
depends 'git'
depends 'puma'
