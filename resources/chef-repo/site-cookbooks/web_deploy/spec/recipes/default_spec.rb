require_relative '../spec_helper'
require 'rspec'

# attribute node.set
describe 'node setting' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new do |node|
      node.set['web_deploy']['default_root'] = '/var/www'
      node.set['web_deploy']['owner'] = 'root'
      node.set['web_deploy']['group'] = 'root'
      node.set['web_deploy']['mode'] = '0775'
      node.set['web_deploy']['app_path'] = '/var/www/app'
      node.set['web_deploy']['repository'] = 'http://172.0.0.1/application/app.git'
      node.set['web_deploy']['revision'] = 'develop'
      node.set['web_deploy']['app_conf_path'] = '/etc/nginx/conf.d'
      node.set['web_deploy']['app_conf_name'] = 'app.conf'
      node.set['nginx_app']['name'] = 'app'
      node.set['nginx_app']['host'] = '0.0.0.0'
      node.set['nginx_app']['port'] = '8080'
      node.set['nginx_app']['index'] = 'index.html'
      node.set['nginx_app']['log'] = '/var/log/nginx/log'
      node.set['nginx_app']['url'] = '/'
      node.set['nginx']['port'] = '80'
      node.set['nginx']['host'] = '0.0.0.0'
      node.set['nginx']['url'] = '/static'
      node.set['nginx']['root'] = '/var/www/app'
      node.set['nginx_log']['owner'] = 'nginx'
      node.set['nginx_log']['group'] = 'nginx'
      node.set['nginx_log']['mode'] = '0775'
    end.converge 'web_deploy::default'
  end
end

# Add Cookbook path
describe 'web_deploy::path' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new(
      cookbook_path: ['cookbooks', 'site-cookbooks']
    ).converge 'web_deploy::default'
  emd
end

# Chef_run web_deploy::default
describe 'chef_run web_deploy::default' do
  # Create default_root
  it 'Create Directory in Dir.exists?(/var/www/app) eq 0' do
    expect(chef_run).to create_directoryr('/var/www/').with(owner: 'root', grooup: 'root', mode: '0775')
    dir = chef_run.directory('/var/www')
    expect(dir.mode).to eq '0775'
    expect(dir).to be_owned_by('root', 'root')
  end

  it 'Not create directory in Dir.exists?(/var/www/app) eq 1' do
    expect(chef_run).to_not create_directory('/var/www').with(owner: 'root', grooup: 'root', mode: '0775')
  end

  # Install Package
  it 'Install git package' do
    expect(chef_run).to install_package('git')
  end

  it 'Install git package yet' do
    expect(chef_run).to_not install_package('git')
  end

  # Download static file for application
  it 'syncs a git with attribute' do
    expect(chef_run).to sync_git('/var/www/app').with(repository: 'http://172.0.0.1/application/app.git', revision: 'develop')
  end

  it 'Not syncs a git with attribute' do
    expect(chef_run).to_not sync_git('/var/www/app').with(repository: 'http://172.0.0.1/application/app.git', revision: 'develop')
  end

  # Create log directory
  it 'Create Directory in Dir.exists?(/var/log/nginx/log) eq 0' do
    expect(chef_run).to create_directory('/var/log/nginx/log').with(owner: 'nginx', group: 'nginx', mode: '0775')
    dir = chef_run.directory('/var/log/nginx/log')
    expect(dir.mode).to eq '0775'
    expect(dir).to be_owned_by('nginx', 'nginx')
  end

  it 'Not create log directory in Dir.exists?(/var/log/nginx/log) eq 1' do
    expect(chef_run).to_not create_directory('/var/log/nginx/log').with(owner: 'nginx', group: 'nginx', mode: '0775')
  end

  # Create app.conf for nginx from template
  it 'Create application config file from template' do
    expect(chef_run).to create_template('/etc/nginx/conf.d/test.conf').with(source: 'app.conf.erb')
  end

  # Nginx restart
  it 'Nginx service restart' do
    expect(chef_run).to restart_service('nginx')
  end
end
