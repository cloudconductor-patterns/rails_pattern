require_relative 'spec_helper'
require 'rspec'

describe 'nginx_part::setup' do
  let(:chef_run) do
    ChefSpec::Runner.new(
      cookbook_path: ['cookbooks', 'site-cookbooks'],
      platform:      'centos',
      version:       '6.5'
    ).converge('nginx_part::setup')
  end

  it 'install nginx' do
    expect(chef_run).to include_recipe 'nginx'
  end
end
