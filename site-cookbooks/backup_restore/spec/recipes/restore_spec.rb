require_relative '../spec_helper'

describe 'backup_restore::restore' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  tmp_dir = '/tmp/backup'

  before do
    chef_run.node.set['backup_restore']['tmp_dir'] = tmp_dir
    chef_run.node.set['backup_restore']['destinations']['enabled'] = %w(s3)
    chef_run.node.set['backup_restore']['destinations']['s3'] = {
      bucket: 's3bucket'
    }

    chef_run.converge(described_recipe)
  end

  it 'create tmp directory' do
    expect(chef_run).to create_directory("#{tmp_dir}/restore").with(
      recursive: true
    )
  end

  it 'delete tem directory' do
    expect(chef_run).to delete_directory("#{tmp_dir}/restore").with(
      recursive: true
    )
  end

  it 'from first of the enabled backup destination will include the recipe of fetch' do
    expect(chef_run).to include_recipe('backup_restore::fetch_s3')
  end

  describe 'contains directory to a restore target sources' do
    it 'include restore_directory recipe' do
      chef_run.node.set['backup_restore']['restore']['target_sources'] = %w(directory)
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('backup_restore::restore_directory')
    end
  end

  describe 'contains directory to a restore target sources' do
    it 'include restore_mysqly recipe' do
      chef_run.node.set['backup_restore']['restore']['target_sources'] = %w(mysql)
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('backup_restore::restore_mysql')
    end
  end

  describe 'contains directory to a restore target sources' do
    it 'include restore_ruby recipe' do
      chef_run.node.set['backup_restore']['restore']['target_sources'] = %w(ruby)
      chef_run.converge(described_recipe)
      expect(chef_run).to include_recipe('backup_restore::restore_ruby')
    end
  end
end
