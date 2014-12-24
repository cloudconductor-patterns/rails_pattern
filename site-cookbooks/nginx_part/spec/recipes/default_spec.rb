require_relative '../spec_helper'

describe 'nginx_part::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  before do
    stub_command('which nginx').and_return(0)
  end

  it 'include setup recipe' do
    expect(chef_run).to include_recipe 'nginx_part::setup'
  end
end
