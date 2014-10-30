require_relative '../spec_helper'

describe 'rails_part::setup' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      cookbook_path: %w(site-cookbooks cookbooks),
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

  it 'install mysql 5.6' do
    expect(chef_run).to include_recipe('yum-mysql-community::mysql56')
  end

  it 'install mysql-community-devel' do
    expect(chef_run).to install_package('mysql-community-devel')
  end

  it 'install sqlite-devel' do
    expect(chef_run).to install_package('sqlite-devel')
  end

  it 'rbenv setup' do
    expect(chef_run).to include_recipe 'rails_part::rbenv_setup'
  end
  it 'ruby-shadow' do

    expect(chef_run).to install_gem_package 'ruby-shadow'
  end

  it 'create user' do
    expect(chef_run).to create_user('rails').with(
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
