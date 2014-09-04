include_recipe 'cron'
# install gem backup with options --no-ri --no-rdoc before include_recipe 'backup'
gem_package 'backup' do
  version node['backup']['version'] if node['backup']['version']
  action :upgrade if node['backup']['upgrade?']
  options '--no-ri --no-rdoc'
end
include_recipe 'backup'
include_recipe 'percona::backup'

# for s3
include_recipe 'yum-epel'
include_recipe 's3cmd-master'
package 'python-dateutil'
