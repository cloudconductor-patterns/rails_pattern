require_relative '../spec_helper'

describe 'backup_restore::restore_mysql' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      cookbook_path: %w(site-cookbooks cookbooks),
      platform:      'centos',
      version:       '6.5'
    ) do |node|
      node.set['backup_restore']['sources']['mysql'] = {
        db_user: 'root',
        db_password: '',
        data_dir: '/etc',
        run_user: 'mysql',
        run_group: 'mysql'
      }
    end
    runner.converge(described_recipe)
  end

  tmp_dir = '/tmp/backup/restore'
  source = {
    db_user: 'root',
    db_password: '',
    data_dir: '/etc',
    run_user: 'mysql',
    run_group: 'mysql'
  }
  full_backup_name = 'mysql_full'
  incremental_backup_name = 'mysql_incremental'
  backup_file = "#{tmp_dir}/#{full_backup_name}.tar"
  backup_dir = "#{tmp_dir}/#{full_backup_name}/MySQL.bkpdir"

  it 'extract_full_backup' do
    allow(IO::File).to receive(:exist?).and_call_original
    allow(IO::File).to receive(:exist?).with(backup_file).and_return(true)
    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with("#{tmp_dir}/#{full_backup_name}").and_return(false)
    expect(chef_run).to run_bash('extract_full_backup').with(
      code: <<-EOF
    tar -xvf #{backup_file} -C #{tmp_dir}
    tar -zxvf #{tmp_dir}/#{full_backup_name}/databases/MySQL.tar.gz -C #{tmp_dir}/#{full_backup_name}
  EOF
    )
  end

  it 'extract_and_apply_incremental_backup' do
    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with(backup_dir).and_return(true)
    allow(Dir).to receive(:exist?).with("#{tmp_dir}/#{incremental_backup_name}").and_return(true)
    expect(chef_run).to run_bash('extract_and_apply_incremental_backup').with(
      code: <<-EOF
    incremental_backups=(`find #{tmp_dir}/#{incremental_backup_name} -mindepth 1 -maxdepth 1`)
    for incremental_backup in ${incremental_backups[@]}
    do
      if [ ! -d ${incremental_backup}/MySQL.bkpdir ]; then
        tar -xvf ${incremental_backup}/#{incremental_backup_name}.tar -C ${incremental_backup}
        tar -zxvf ${incremental_backup}/#{incremental_backup_name}/databases/MySQL.tar.gz -C ${incremental_backup}
        innobackupex --apply-log --redo-only #{backup_dir} \
          --incremental-dir ${incremental_backup}/MySQL.bkpdir
      fi
    done
  EOF
    )
  end

  it 'mysqld stop' do
    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with(backup_dir).and_return(true)
    expect(chef_run).to stop_service('mysqld')
  end

  it 'delete_old_data' do
    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with(backup_dir).and_return(true)
    expect(chef_run).to run_bash('delete_old_data').with(
     code: "rm -rf #{source[:data_dir]}/*"
    )
  end

  it 'restore_backup' do
    allow(Dir).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).with(backup_dir).and_return(true)
    allow(Dir).to receive(:exist?).with("#{tmp_dir}/#{full_backup_name}/MySQL.bkpdir").and_return(true)
    expect(chef_run).to run_bash('restore_backup')
  end

  it 'mysqld start' do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(backup_file).and_return(true)
    expect(chef_run).to start_service('mysqld')
  end
end
