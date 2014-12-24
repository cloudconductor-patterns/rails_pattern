require_relative '../spec_helper'
require 'chefspec'

describe 'mysql_part::create_database' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  db_host = '127.0.0.1'
  db_user = 'root'
  db_passwd = 'password'
  db_connection = {
    host: db_host,
    username: db_user,
    password: db_passwd
  }

  before do
    chef_run.node.set['mysql']['server_root_password'] = db_passwd
  end

  it 'include mysql recipe of database cookbook' do
    chef_run.converge(described_recipe)
    expect(chef_run).to include_recipe('database::mysql')
  end

  it 'create database' do
    database_name = 'chefsdb'
    db_encode = 'utf8'
    chef_run.node.set['mysql_part']['app']['database'] = database_name
    chef_run.node.set['mysql_part']['app']['endoding'] = db_encode
    chef_run.converge(described_recipe)

    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_database,
      :create,
      database_name
    ).with(
      connection: db_connection,
      encoding: db_encode
    )
  end

  it 'create database user for application' do
    app_user_name = 'app_user'
    app_user_pass = 'passwd'
    chef_run.node.set['mysql_part']['app']['username'] = app_user_name
    chef_run.node.set['mysql_part']['app']['password'] = app_user_pass
    chef_run.converge(described_recipe)

    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_database_user,
      :create,
      'create database user'
    ).with(
      connection: db_connection,
      username: app_user_name,
      password: app_user_pass
    )
  end

  it 'grant auth of the db to the application user' do
    database_name = 'chefsdb'
    app_user_name = 'app_user'
    app_user_pass = 'passwd'
    privileges = [:all]
    require_ssl = false
    chef_run.node.set['mysql_part']['app']['database'] = database_name
    chef_run.node.set['mysql_part']['app']['username'] = app_user_name
    chef_run.node.set['mysql_part']['app']['password'] = app_user_pass
    chef_run.node.set['mysql_part']['app']['privileges'] = privileges
    chef_run.node.set['mysql_part']['app']['require_ssl'] = require_ssl
    chef_run.converge(described_recipe)

    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_database_user,
      :grant,
      'Grant database'
    ).with(
      connection: db_connection,
      username: app_user_name,
      database_name: database_name,
      host: '%',
      privileges: privileges,
      require_ssl: require_ssl
    )
  end

  it 'flush the privileges' do
    ChefSpec::Matchers::ResourceMatcher.new(
      :mysql_database,
      :query,
      'flush the privileges'
    ).with(
      connection: db_connection,
      sql: 'flush privileges'
    )
  end
end
