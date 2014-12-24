require_relative '../spec_helper'
require 'chefspec'

describe 'mysql_part::setup' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'include server recipe of mysql cookbook' do
    expect(chef_run).to include_recipe 'mysql::server'
  end

  it 'include client recipe of mysql cookbook' do
    expect(chef_run).to include_recipe 'mysql::client'
  end
end
