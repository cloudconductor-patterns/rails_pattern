require 'spec_helper'
require 'json'

describe 'web_configure' do
  chef_run = ChefSpec::SoloRunner.new

  before(:all) do
    chef_run.node.normal_attrs = property[:chef_attributes]
    chef_run.converge('role[web_configure]')
  end

  it 'is create maintenance directory' do
    expect(file("#{chef_run.node['nginx']['default_root']}/maintenance"))
      .to be_directory
      .and be_owned_by('root')
      .and be_grouped_into('root')
  end

  it 'is create maintenance index file' do
    expect(file("#{chef_run.node['nginx']['default_root']}/maintenance/index.html"))
      .to be_file
      .and be_owned_by('root')
      .and be_grouped_into('root')
  end

  it 'is maintanance index file of content is nginx_part.maintanance attribute value' do
    expect(file("#{chef_run.node['nginx']['default_root']}/maintenance/index.html"))
      .to contain(chef_run.node['nginx_part']['maintenance'])
  end

  it 'is create default.conf' do
    expect(file("#{chef_run.node['nginx']['dir']}/conf.d/default.conf"))
      .to be_file
      .and be_owned_by('root')
      .and be_grouped_into('root')
      .and be_mode(644)
      .and contain("root   #{chef_run.node['nginx']['default_root']}/maintenance")
  end

  it 'is nginx service is running ' do
    expect(service('nginx')).to be_running
  end
end
