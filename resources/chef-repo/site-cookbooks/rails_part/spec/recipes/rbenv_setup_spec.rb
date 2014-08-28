require_relative '../spec_helper'

describe 'rails_part::rbenv_setup' do
  let(:chef_run) do
    ChefSpec::Runner.new(
      cookbook_path:  ['site-cookbooks', 'cookbooks'],
      platform:       'centos',
      version:        '6.5'
    ) do |node|
      node.set['rbenv_setup'] = {
        ruby_version: '2.1.1',
        global:       true
      }
    end.converge('rails_part::rbenv_setup')
  end

  it 'include recipes' do
    expect(chef_run).to include_recipe 'rbenv::default'
    expect(chef_run).to include_recipe 'rbenv::ruby_build'
  end

  it 'rbenv_ruby install' do
    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :rbenv_ruby,
      :install,
      '2.1.1'
    ).with(
      ruby_version: '2.1.1',
      global:       true
    )
  end
  it 'bundler install' do
    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
        :rbenv_gem,
        :install,
        'bundler'
      ).with(
        ruby_version: '2.1.1'
      )
  end
end
