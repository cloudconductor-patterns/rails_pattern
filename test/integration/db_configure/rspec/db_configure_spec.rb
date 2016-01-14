require 'spec_helper'
require 'json'

describe 'db_configure' do
  chef_run = ChefSpec::SoloRunner.new

  before(:all) do
    chef_run.node.normal_attrs = property[:chef_attributes]
    chef_run.converge('role[db_configure]')
  end

  it 'is listen mysql port' do
    expect(port(3306)).to be_listening # .with('tcp') # ...TCP(ipv4 or ipv6)
  end

  it 'is create db and database user is settings from attributes' do
    database = chef_run.node['mysql_part']['app']['database'] || 'application'
    username = chef_run.node['mysql_part']['app']['username'] || 'application'
    generated_passwd = OpenSSL::Digest::SHA256.hexdigest(chef_run.node['cloudconductor']['salt'] + 'database')
    password = chef_run.node['mysql_part']['app']['password'] || generated_passwd

    expect(command("mysql #{database} -u #{username} -p#{password} -e 'SHOW DATABASES;'").exit_status).to eq(0)
  end
end
