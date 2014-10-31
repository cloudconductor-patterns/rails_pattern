require 'spec_helper'
require 'cloud_conductor_utils/consul'

describe service('iptables') do
  it { should_not be_enabled }
end

describe 'connect mysql' do
  servers = property[:servers]
  db_host = servers.each_value.select do |server|
    server[:roles].include?('db')
  end.first

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
