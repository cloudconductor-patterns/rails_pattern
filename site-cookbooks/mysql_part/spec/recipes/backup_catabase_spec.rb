require_relative '../spec_helper'
require 'chefspec'

describe 'mysql_part::backup_database' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  it 'create database' do
    backup_directory = '/var/cloudconductor/backups/mysql'
    chef_run.node.set['mysql_part']['backup_directory'] = backup_directory
    chef_run.converge(described_recipe)

    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :directory,
      :create,
      backup_directory
    ).with(
      recursive: true,
      mode: '0777'
    )
  end

  it 'dump database in shell script' do
    allow_any_instance_of(Chef::Resource).to receive(:generate_password).and_return('GENERATED_PASSWORD')

    chef_run.converge(described_recipe)

    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :execute,
      :run,
      'backup_database'
    ).with(
      user: 'mysql',
      command: 'mysqldump -u application -pGENERATED_PASSWORD -x --all-databases > /var/cloudconductor/backups/mysql/dump.sql'
    )
  end
end
