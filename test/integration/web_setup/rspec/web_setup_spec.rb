require 'spec_helper'
require 'json'

describe 'web_setup' do
  chef_run = ChefSpec::SoloRunner.new

  before(:all) do
    stub_command('which nginx').and_return(1)
    chef_run.node.normal_attrs = property[:chef_attributes]
    chef_run.converge('role[web_setup]')
  end

  it 'is installed nginx package' do
    expect(package(chef_run.node['nginx']['package_name'])).to be_installed
  end

  it 'is s nginx service enabled and running' do
    expect(service('nginx')).to be_enabled.and be_running
  end
end
