require_relative '../spec_helper'
require 'rspec'

# Start spec test
# prepare 1 node setting
describe 'node setting' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new do |node|
      node.set['create_user']['host'] = 'localhost'
      node.set['create_user']['username'] = 'root'
      node.set['create_user']['pass'] = 'ilikerundompasswords'
      node.set['create_user']['new_username'] = 'appuser'
      node.set['create_user']['new_password'] = 'ilikerandompasswords'
      node.set['create_user']['database_name'] = 'app'
      node.set['create_user']['privileges'] = [
        :select,
        :update,
        :insert
      ]
      node.set['create_user']['require_ssl'] = 'ture'
    end.converge 'db::create_user'
  end
end

# prepare 2 enviroment setting

# prepare 3 add cookbook_path
describe 'db::cookbook_path' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new(
      cookbook_path: ['cookbooks', 'site-cookbooks']
    ).converge 'db::create_user'
  end
end

# chef_run db::create_user
describe 'chef_run db::create_user' do
  # create user
  it 'create mysq_database_user' do
    ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_database_user, :create, 'appuser'
    ).with(new_password: 'ilikerandomupasswords')
  end
  # grant user
  it 'grant mysql_database_user' do
    ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_database_user, :grant, 'appuser'
    ).with(
      new_password: 'ilikerandompasswords',
      database_name: 'app',
      host: 'localhost',
      privileges: [':select', ':update', ':insert'],
      require_ssl: 'ture'
    )
  end
end
