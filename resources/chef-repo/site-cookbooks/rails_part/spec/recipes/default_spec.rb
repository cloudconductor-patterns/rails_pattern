require_relative '../spec_helper'

describe 'rails_part::setup' do
  let(:chef_run) do
    ChefSpec::Runner.new(
      cookbook_path: ['site-cookbooks', 'cookbooks'],
      platform:      'centos',
      version:       '6.5'
    ).converge('rails_part::setup')
  end

  it 'include setup' do
    expect(chef_run).to include_recipe 'rails_part::setup'
  end
end