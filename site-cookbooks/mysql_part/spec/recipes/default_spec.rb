require_relative '../spec_helper'
require 'chefspec'

describe 'mysql_part default spec' do
  let(:chef_run) do
    ChefSpec::Runner.new(
      cookbook_path: ['cookbooks', 'site-cookbooks'],
      platform: 'centos',
      version: '6.5'
    ).converge('mysql_part::default')
  end

  it 'include mysql_part::setup' do
    expect(chef_run).to include_recipe 'mysql_part::setup'
  end
end
