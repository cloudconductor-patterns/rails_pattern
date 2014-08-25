require_relative '../spec_helper'

describe 'db::create_database' do
  subject { ChefSpec::Runner.new.converge(described_recipe) }

  # install Database Package
  it 'install package' do
    expect(chef_run).to install_package('mysql')
  end

  # Create Database
#    it 'create database' do
#    expect(chef_run).to
#  end
  it 'create db 1' do

  end

  # Flush privileges

end

# prepare 1 node setting
describe 'db::create_data' do
  let( :chef_run ) do
    chef_run = ChefSpec::ChefRunner.new do |node|
      node.set['create_user']['host'] = 'root'
      node.set['create_user']['username'] = 'root'
      node.set['create_user']['pass'] = 'ilikerundompasswords'
    end.converge 'db::create_database'
  end
end

# prepare 2 environment setting

# prepare 3 add cookbook_path
describe 'db::cookbook_path' do
  let( :chef_run ) do
    ChefSpec::ChefRunner.new(:cookbook_path
  end
end
