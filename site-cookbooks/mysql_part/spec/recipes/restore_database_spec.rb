require_relative '../spec_helper'
require 'chefspec'

describe 'mysql_part::restore_database' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  it 'restore database in shell script' do
    allow_any_instance_of(Chef::Resource).to receive(:generate_password).and_return('GENERATED_PASSWORD')
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/var/cloudconductor/backups/mysql/dump.sql').and_return(true)

    chef_run.converge(described_recipe)

    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :execute,
      :run,
      'restore_database'
    ).with(
      user: 'mysql',
      command: 'mysql -u application -pGENERATED_PASSWORD < /var/cloudconductor/backups/mysql/dump.sql'
    )
  end
end
