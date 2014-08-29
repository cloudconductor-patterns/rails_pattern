require_relative '../spec_helper'
require 'chefspec'

# Start spec test
# prepare 1 node setting
describe 'Create database spec' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new(cookbook_path: ['cookbooks', 'site-cookbooks']) do |node|
      node.set['mysql_part']['host'] = 'root'
      node.set['mysql_part']['username'] = 'root'
      node.set['mysql_part']['password'] = 'ilikerundompasswords'
      node.set['mysql_part']['database_name'] = 'app'
      node.set['mysql_part']['encoding'] = 'utf8'
    end.converge 'mysql_part::create_database'
  end

  # chef_run db::create_database
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
