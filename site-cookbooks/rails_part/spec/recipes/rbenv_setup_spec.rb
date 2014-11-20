require_relative '../spec_helper'

describe 'rails_part::rbenv_setup' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  before do
    chef_run.node.set['rails_part']['ruby']['version'] = '2.1.2'
    chef_run.converge(described_recipe)
  end

  it 'include rbenv default recipes' do
    expect(chef_run).to include_recipe 'rbenv::default'
  end

  it 'include rbenv ruby_build recipes' do
    expect(chef_run).to include_recipe 'rbenv::ruby_build'
  end

  it 'install rbenv and ruby' do
    chef_run.node.set['rails_part']['ruby']['global'] = true
    chef_run.converge(described_recipe)

    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :rbenv_ruby,
      :install,
      '2.1.2'
    ).with(
      ruby_version: '2.1.2',
      global:       true
    )
  end

  it 'install bundler gem' do
    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
        :rbenv_gem,
        :install,
        'bundler'
      ).with(
        ruby_version: '2.1.2'
      )
  end
end
