require 'spec_helper'
require 'json'

describe 'ap_setup' do
  chef_run = ChefSpec::SoloRunner.new

  before(:all) do
    chef_run.node.normal_attrs = property[:chef_attributes]
    chef_run.converge('role[ap_setup]')
  end

  it 'is installed git package' do
    expect(package('git')).to be_installed
  end

  it 'is installed gcc package' do
    expect(package('gcc')).to be_installed
  end

  it 'is installed gcc-c++ package' do
    expect(package('gcc-c++')).to be_installed
  end

  it 'is installed make package' do
    expect(package('make')).to be_installed
  end

  it 'is installed mysql-community-devel package' do
    expect(package('mysql-community-devel')).to be_installed
  end

  it 'is installed sqlite-devel package' do
    expect(package('sqlite-devel')).to be_installed
  end

  it 'is installed ruby' do
    expect(command('source /etc/profile.d/rbenv.sh; ruby -v').stdout)
      .to match(/#{chef_run.node['rails_part']['ruby']['version']}/)
  end

  it 'is installed bundler gem' do
    expect(command('source /etc/profile.d/rbenv.sh; gem list').stdout).to match(/bundler/)
  end

  it 'is installed bundler gem' do
    expect(command('source /etc/profile.d/rbenv.sh; gem list').stdout).to match(/ruby-shadow/)
  end

  it 'is create rails group' do
    expect(group(chef_run.node['rails_part']['user']['group'])).to exist
  end

  it 'is create rails user' do
    expect(user(chef_run.node['rails_part']['user']['name']))
      .to exist
      .and have_home_directory("/home/#{chef_run.node['rails_part']['user']['name']}")
      .and belong_to_group(chef_run.node['rails_part']['user']['group'])
  end
end
