require 'spec_helper'
require 'json'

describe 'db_setup' do
  chef_run = ChefSpec::SoloRunner.new

  before(:all) do
    chef_run.node.normal_attrs = property[:chef_attributes]
    chef_run.converge('role[db_setup]')
  end

  it 'is create yum global config' do
    expect(file('/etc/yum.conf')).to be_file
  end

  it 'is installed mysql package' do
    expect(package('mysql-community-client')).to be_installed
  end

  it 'is installed mysql-devel package' do
    expect(package('mysql-community-devel')).to be_installed
  end

  it 'is installed mysql-server package' do
    expect(package('mysql-community-server')).to be_installed
  end

  it 'is mysql service enabled and running' do
    expect(service('mysqld')).to be_enabled.and be_running
  end
end
