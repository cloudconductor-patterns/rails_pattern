require 'spec_helper'
require 'mysql2'
require '/opt/cloudconductor/lib/cloud_conductor/consul_util'

describe service('iptables') do
  it { should_not be_enabled }
end

describe 'connect mysql' do
  param = property[:consul_parameters]
  servers = property[:servers]
  db_host = servers.each_value.select do |server|
    server[:roles].include?('db')
  end.first

  if param[:cloudconductor] && db_host[:private_ip]
    hostname = db_host[:private_ip]

    if param[:mysql_part] && param[:mysql_part][:app] && param[:mysql_part][:app][:username]
      username = param[:mysql_part][:app][:username]
    else
      username = 'rails'
    end

    if param[:mysql_part] && param[:mysql_part][:app] && param[:mysql_part][:app][:password]
      password = param[:mysql_part][:app][:passowrd]
    else
      password = 'todo_replace_randompassword'
    end

    if param[:mysql_part] && param[:mysql_part][:app] && param[:mysql_part][:app][:database]
      database = param[:mysql_part][:app][:database]
    else
      database = 'rails'
    end

    it do
      expect do
        Mysql2::Client.new(
          host: hostname,
          username: username,
          password: password,
          database: database)
      end.to_not raise_error
    end
  else

    it 'consul parameter is missing: cloudconductor or cloudconductor/servers' do
      fail
    end
  end
end
