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

  it 'install mysql-devel' do
    expect(chef_run).to install_package('mysql-devel')
  end

  it 'install sqlite-devel' do
    expect(chef_run).to install_package('sqlite-devel')
  end

  it 'rbenv setup' do
    expect(chef_run).to include_recipe 'rails_part::rbenv_setup'
  end

  it 'iptables disabled' do
    expect(chef_run).to include_recipe 'iptables::disabled'
  end

  it 'create user' do
    expect(chef_run).to create_user('rails').with(
      password: '$1$ID1d8IuR$oyeSAB1Z5gHptbJimJ8Fr/',
      supports: {
        manage_home: true
      }
    )
  end

  it 'create group' do
    expect(chef_run).to create_group('rails').with(
      members: ['rails'],
      append: true
    )
  end
end
