require 'spec_helper'

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
    describe host(hostname) do
      it { should be_reachable.with(port: 3306) }
    end
  else
    it 'consul parameter is missing: cloudconductor or cloudconductor/servers' do
      fail
    end
  end
end
