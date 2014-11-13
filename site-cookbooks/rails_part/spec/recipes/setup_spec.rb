require_relative '../spec_helper'

describe 'rails_part::setup' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'include git recipe' do
    expect(chef_run).to include_recipe 'git'
  end

  it 'include build-essential for rhel' do
    expect(chef_run.node[:platform_family]).to eq('rhel')
    expect(chef_run).to include_recipe('build-essential::_rhel')
  end

  it 'include mysql56 recipe of um-mysql-community cookbook' do
    expect(chef_run).to include_recipe('yum-mysql-community::mysql56')
  end

  it 'install mysql-community-devel package' do
    expect(chef_run).to install_package('mysql-community-devel')
  end

  it 'install sqlite-devel package' do
    expect(chef_run).to install_package('sqlite-devel')
  end

  it 'include rbenv_setup recipe' do
    expect(chef_run).to include_recipe 'rails_part::rbenv_setup'
  end

  it 'install ruby-shadow gem' do
    expect(chef_run).to install_gem_package 'ruby-shadow'
  end

  it 'create user' do
    chef_run.node.set[:rails_part][:user][:name] = 'chefspec_user'
    chef_run.node.set[:rails_part][:user][:passwd] = 'chefspec_pwd'
    chef_run.node.set[:rails_part][:user][:manage_home] = true
    chef_run.converge(described_recipe)

    expect(chef_run).to create_user('chefspec_user').with(
      password: 'chefspec_pwd',
      supports: {
        manage_home: true
      }
    )
  end

  it 'create group' do
    chef_run.node.set[:rails_part][:user][:group] = 'chefspec_group'
    chef_run.node.set[:rails_part][:user][:name] = 'chefspec_user'
    chef_run.converge(described_recipe)

    expect(chef_run).to create_group('chefspec_group').with(
      members: ['chefspec_user'],
      append: true
    )
  end
end
