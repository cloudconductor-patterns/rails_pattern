require_relative '../spec_helper'
require 'chefspec'

describe 'mysql_part setup spec' do
  let(:chef_run) do
    ChefSpec::Runner.new(
      cookbook_path: ['cookbooks', 'site-cookbooks'],
      platform: 'centos',
      version: '6.5'
    ).converge('mysql_part::setup')
  end

  it 'include mysql::server' do
    expect(chef_run).to include_recipe 'mysql::server'
  end

  it 'include mysql::client' do
    expect(chef_run).to include_recipe 'mysql::client'
  end

  it 'include mysql_part::create_database' do
    expect(chef_run).to include_recipe 'mysql_part::create_database'
  end
end
