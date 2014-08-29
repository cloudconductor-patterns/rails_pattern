require_relative '../spec_helper'
require 'chefspec'

# Start spec test
# prepare 1 node setting
describe 'node setting' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new do |node|
      node.set['create_user']['host'] = 'root'
      node.set['create_user']['username'] = 'root'
      node.set['create_user']['pass'] = 'ilikerundompasswords'
      node.set['create_user']['database_name'] = 'app'
      node.set['create_database']['encoding'] = 'utf8'
    end.converge 'db::create_database'
  end
end

# prepare 2 environment setting

# prepare 3 add cookbook_path
describe 'db::cookbook_path' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new(
      cookbook_path: ['cookbooks', 'site-cookbooks']
    ).converge 'db::create_database'
  end
end

# chef_run db::create_database
describe 'chef_run db::create_database' do
  # Create Database
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
