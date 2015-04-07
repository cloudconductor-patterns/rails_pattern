require 'spec_helper'
require 'cloud_conductor_utils/consul'

describe service('iptables') do
  it { should_not be_enabled }
end

describe 'connect to the server have a key that [:roles] to db' do
  servers = property[:servers]
  db_host = servers.each_value.find do |server|
    server[:roles].include?('db')
  end

  if db_host[:private_ip]
    hostname = db_host[:private_ip]
    describe command("hping3 -S #{hostname} -p 3306 -c 5") do
      its(:stdout) { should match(/sport=3306 flags=SA/) }
    end
  else

    it 'consul parameter is missing: cloudconductor or cloudconductor/servers' do
      fail
    end
  end
end
