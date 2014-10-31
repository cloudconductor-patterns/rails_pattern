require_relative '../spec_helper'

describe 'nginx_part::setup' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      cookbook_path: ['cookbooks', 'site-cookbooks'],
      platform:      'centos',
      version:       '6.5'
    ).converge(described_recipe)
  end

  before do
    stub_command('which nginx').and_return(0)
  end

  it 'install nginx' do
    expect(chef_run).to include_recipe('nginx')
  end
end
