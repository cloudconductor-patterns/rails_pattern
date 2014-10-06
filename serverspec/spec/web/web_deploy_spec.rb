require 'spec_helper'

describe file('/etc/nginx/conf.d/default.conf') do
  it { should_not be_file }
end

describe 'connect ap_svr' do
  params = property[:consul_parameters]

  apps = params[:cloudconductor][:applications]

  apps.each do |app_name, app|

    if app[:type] != "optional"
      describe "#{app_name} check" do

        if app[:parameters][:app_port]
          port = app[:parameters][:app_port]
        else
          port = 8080
        end

        describe command( \
          "curl --noproxy #{params[:cloudconductor][:ap_host]} \
          'http://#{params[:cloudconductor][:ap_host]}:#{port}'") do
          it { should return_exit_status 0 }
        end

      end
    end
  end
end
