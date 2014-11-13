require_relative '../spec_helper'

describe 'rails_part::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'include setup' do
    expect(chef_run).to include_recipe 'rails_part::setup'
  end
end
