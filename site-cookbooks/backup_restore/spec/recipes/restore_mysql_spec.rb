require_relative '../spec_helper'

describe 'backup_restore::restore_mysql' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  tmp_dir = '/tmp/backup'

  before do
    chef_run.node.set['backup_restore']['tmp_dir'] = tmp_dir
    chef_run.converge(described_recipe)
  end

  describe 'full backup file is exist and is not yet uncompress' do
    it 'extract full backup data from compress file' do
      allow(IO::File).to receive(:exist?).and_call_original
      allow(IO::File).to receive(:exist?).with("#{tmp_dir}/restore/mysql_full.tar").and_return(true)
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with("#{tmp_dir}/restore/mysql_full").and_return(false)
      chef_run.converge(described_recipe)

      expect(chef_run).to run_bash('extract_full_backup')
    end
  end

  describe 'full backup uncompress directory is exist' do
    before do
      allow(Dir).to receive(:exist?).and_call_original
      allow(Dir).to receive(:exist?).with("#{tmp_dir}/restore/mysql_full/MySQL.bkpdir").and_return(true)
      chef_run.converge(described_recipe)
    end

    describe 'incremental backup files is exist' do
      it 'extract incremental backup data from compress filesa and apply to mysql log' do
        allow(Dir).to receive(:exist?).with("#{tmp_dir}/restore/mysql_incremental").and_return(true)
        chef_run.converge(described_recipe)

        expect(chef_run).to run_bash('extract_and_apply_incremental_backup')
      end
    end

    it 'mysqld stop' do
      expect(chef_run).to stop_service('mysqld')
    end

    describe 'old data is exist' do
      it 'delete old data' do
        data_dir = '/etc/mysql/data'
        chef_run.node.set['backup_restore']['sources']['mysql']['data_dir'] = data_dir
        allow(Dir).to receive(:[]).and_call_original
        allow(Dir).to receive(:[]).with("#{data_dir}/*").and_return(['foo'])
        chef_run.converge(described_recipe)

        expect(chef_run).to run_bash('delete_old_data').with(
          code: "rm -rf #{data_dir}/*"
        )
      end
    end

    it 'restore_backup' do
      expect(chef_run).to run_bash('restore_backup')
    end
  end

  it 'mysqld start' do
    allow(IO::File).to receive(:exist?).and_call_original
    allow(IO::File).to receive(:exist?).with("#{tmp_dir}/restore/mysql_full.tar").and_return(true)
    chef_run.converge(described_recipe)
    expect(chef_run).to start_service('mysqld')
  end
end
