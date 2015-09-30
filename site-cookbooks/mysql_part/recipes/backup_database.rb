#
# Cookbook Name:: mysql_part
# Recipe:: backup_database
#
# Copyright 2014, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
directory node['mysql_part']['backup_directory'] do
  recursive true
  mode '0777'
  action :create
end

execute 'backup_database' do
  path = File.join(node['mysql_part']['backup_directory'], 'dump.sql')
  password = generate_password('database')

  command "mysqldump -u application -p#{password} -x --all-databases > #{path}"
  user 'mysql'
  action :run
end
