#
# Cookbook Name:: mysql_part
# Recipe:: restore_database
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
execute 'restore_database' do
  path = File.join(node['mysql_part']['backup_directory'], 'dump.sql')
  password = generate_password('database')

  command "mysql -u application -p#{password} < #{path}"
  user 'mysql'
  action :run
  only_if { File.exist?(path) }
end
