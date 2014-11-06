require 'spec_helper'

describe file('/etc/nginx/conf.d/default.conf') do
  it { should_not be_file }
end

describe 'connect ap_svr' do
  params = property[:consul_parameters]
  servers = property[:servers]
  ap_host = servers.each_value.select do |server|
    server[:roles].include?('ap')
  end.first
  apps = params[:cloudconductor][:applications]

  apps.each do |app_name, app|
    next if app[:type] == 'optional'
    describe "#{app_name} check" do
      if app[:parameters][:app_port]
        port = app[:parameters][:app_port]
      else
        port = 8080
      end
      describe command( \
        "curl --noproxy #{ap_host[:private_ip]} \
        'http://#{ap_host[:private_ip]}:#{port}'") do
        its(:exit_status) { should eq 0 }
      end
    end
  end
end
