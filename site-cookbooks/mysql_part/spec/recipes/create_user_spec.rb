require_relative '../spec_helper'
require 'rspec'

# Start spec test
# prepare 1 node setting
describe 'create_user spec' do
  let(:chef_run) do
    ChefSpec::ChefRunner.new(
      cookbook_path: ['cookbooks', 'site-cookbooks']
    ) do |node|
      node.set['mysql_part']['host'] = 'localhost'
      node.set['mysql_part']['username'] = 'root'
      node.set['mysql_part']['pass'] = 'ilikerundompasswords'
      node.set['mysql_part']['new_username'] = 'appuser'
      node.set['mysql_part']['new_password'] = 'ilikerandompasswords'
      node.set['mysql_part']['database_name'] = 'app'
      node.set['mysql_part']['privileges'] = [:all]
      node.set['mysql_part']['require_ssl'] = 'ture'
    end.converge 'mysql_part::create_user'
  end

  # chef_run mysql_part::create_user
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
