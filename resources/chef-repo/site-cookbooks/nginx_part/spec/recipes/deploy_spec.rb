require_relative '../spec_helper'
require 'rspec'

describe 'nginx_part::deploy' do
  # attribute node.set
  let(:chef_run) do
    ChefSpec::Runner.new(cookbook_path: ['cookbooks', 'site-cookbooks']) do |node|
      node.set['nginx_part']['static_root'] = '/var/www'
      node.set['nginx_part']['static_owner'] = 'root'
      node.set['nginx_part']['static_group'] = 'root'
      node.set['nginx_part']['static_mode'] = '0775'
      node.set['nginx_part']['app_name'] = 'app'
      node.set['nginx_part']['app_path'] = '/var/www/app'
      node.set['cloudconductor']['application_url'] = 'http://172.0.0.1/application/app.git'
      node.set['cloudconductor']['application_revision'] = 'master'
      node.set['nginx_part']['app_conf_path'] = '/etc/nginx/conf.d'
      node.set['nginx_part']['app_conf_name'] = 'app.conf'
      node.set['nginx_part']['app_log_dir'] = '/var/log/nginx/log'
      node.set['cloudconductor']['ap_host'] = '0.0.0.0'
      node.set['nginx_part']['ap_svr_port'] = '8080'
      node.set['nginx_part']['ap_svr_index'] = 'index.html'
      node.set['nginx_part']['ap_svr_url'] = '/'
      node.set['nginx_part']['web_svr_port'] = '80'
      node.set['nginx_part']['web_svr_host'] = '0.0.0.0'
      node.set['nginx_part']['web_svr_url'] = '/static'
      node.set['nginx_part']['log_owner'] = 'nginx'
      node.set['nginx_part']['log_group'] = 'nginx'
      node.set['nginx_part']['log_mode'] = '0775'
    end.converge 'nginx_part::deploy'
  end

  # Chef_run nginx_part::deploy
  # Delete /etc/nginx/conf.d/default.conf
  it 'Delete /etc/nginx/conf.d/default.conf' do
    expect(chef_run).to delete_file('/etc/nginx/conf.d/default.conf')
  end

  # Delete symbolic link
  it 'Delete /etc/nginx/sites-enabled/000-default' do
    expect(chef_run).to delete_link('/etc/nginx/sites-enabled/000-default')
  end
  # Create default_root
  it 'Create Directory' do
    expect(chef_run).to create_directory('/var/www').with(
      owner: 'root', group: 'root', mode: '0775'
    )
  end

  # Install Package
  it 'Install git package' do
    expect(chef_run).to install_package('git')
  end

  # Download static file for application
  it 'syncs a git with attribute' do
    expect(chef_run).to sync_git('/var/www/app').with(
      repository: 'http://172.0.0.1/application/app.git', revision: 'master'
    )
  end

  # Create log directory
  it 'Create Directory' do
    expect(chef_run).to create_directory('/var/log/nginx/log').with(
      owner: 'nginx', group: 'nginx', mode: '0775'
    )
  end

  # Create app.conf for nginx from template
  let(:template) { chef_run.template('/etc/nginx/conf.d/app.conf') }
  it 'Create application config file from template' do
    expect(chef_run).to create_template('/etc/nginx/conf.d/app.conf').with(mode: '0644')
    expect(template).to notify('service[nginx]')
  end
end
