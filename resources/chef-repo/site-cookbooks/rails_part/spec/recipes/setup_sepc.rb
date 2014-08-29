require_relative '../spec_helper'

describe 'rails_part::setup' do
  let(:chef_run) do
    ChefSpec::Runner.new(
      cookbook_path: ['site-cookbooks', 'cookbooks'],
      platform:      'centos',
      version:       '6.5'
    ).converge('rails_part::setup')
  end

  it 'install git' do
    expect(chef_run).to include_recipe 'git'
  end

  it 'install build-essential' do
    expect(chef_run).to include_recipe('build-essential::_rhel')
  end

  it 'rbenv setup' do
    expect(chef_run).to include_recipe 'rails_part::rbenv_setup'
  end

  it 'iptables disabled' do
    expect(chef_run).to include_recipe 'iptables::disabled'
  end

  it 'create application user' do
    expect(chef_run).to include_recipe 'rails_part::create_user'
  end
end
