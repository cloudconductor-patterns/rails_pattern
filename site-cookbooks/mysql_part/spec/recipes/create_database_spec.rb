require_relative '../spec_helper'
require 'chefspec'

# Start spec test
# prepare 1 node setting
describe 'Create database spec' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      cookbook_path: ['cookbooks', 'site-cookbooks'],
      platform: 'centos',
      version: '6.5'
    ) do |node|
      node.set['mysql_part']['app']['database'] = 'app'
      node.set['mysql_part']['app']['username'] = 'root'
      node.set['mysql_part']['app']['password'] = 'todo_replace_randompassword'
      node.set['mysql_part']['app']['encoding'] = 'utf8'
      node.set['mysql_part']['app']['privileges'] = [:all]
      node.set['mysql_part']['app']['require_ssl'] = false
    end.converge 'mysql_part::create_database'
  end

  it 'include database::mysql' do
    expect(chef_run).to include_recipe('database::mysql')
  end

  it 'create mysql_database' do
    ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_database, :create, 'app'
    ).with(encoding: 'utf8')
  end
  # run sql
  it 'flush the privileges' do
    ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_database, :query, 'flush the privileges'
    ).with(sql: 'flush privileges')
  end
end
