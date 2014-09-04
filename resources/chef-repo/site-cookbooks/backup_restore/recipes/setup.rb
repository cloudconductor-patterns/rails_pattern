include_recipe 'cron'
include_recipe 'backup'
include_recipe 'percona::backup'

# for s3
include_recipe 'yum-epel'
include_recipe 's3cmd-master'
package 'python-dateutil'
