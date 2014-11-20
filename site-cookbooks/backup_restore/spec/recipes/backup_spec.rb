require_relative '../spec_helper'

describe 'backup_restore::backup' do

  let(:chef_run) { ChefSpec::SoloRunner.new }

  describe 'contains directory to a enabled sources' do
    it 'include backup_directory recipe' do
      chef_run.node.set['backup_restore']['sources']['enabled'] = %w(directory)
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('backup_restore::backup_directory')
    end
  end

  describe 'contains mysql to a enabled sources' do
    it 'include backup_mysql recipe' do
      chef_run.node.set['backup_restore']['sources']['enabled'] = %w(mysql)
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('backup_restore::backup_mysql')
    end
  end

  describe 'contains ruby to a enabled sources' do
    it 'include backup_ruby recipe' do
      chef_run.node.set['backup_restore']['sources']['enabled'] = %w(ruby)
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('backup_restore::backup_ruby')
    end
  end
end
