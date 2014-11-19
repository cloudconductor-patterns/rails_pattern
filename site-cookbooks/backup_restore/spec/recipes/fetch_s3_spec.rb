require_relative '../spec_helper'

describe 'backup_restore::fetch_s3' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  s3_bucket = 's3bucket'
  s3_prefix = '/backup'
  tmp_dir = '/tmp'

  before do
    chef_run.node.set['backup_restore']['tmp_dir'] = tmp_dir
    chef_run.node.set['backup_restore']['destinations']['s3'] = {
      bucket: s3_bucket,
      prefix: s3_prefix
    }
    chef_run.converge(described_recipe)
  end

  describe 'contains backup type to a target sources' do
    it 'download backup data of backup type' do
      source = 'directory'
      chef_run.node.set['backup_restore']['restore']['target_sources'] = [source]
      allow(::File).to receive(:exist?).and_call_original
      allow(::File).to receive(:exist?).with("#{tmp_dir}/restore/#{source}_full.tar").and_return(false)
      expect_any_instance_of(Mixlib::ShellOut).to receive(:run_command)
      expect_any_instance_of(Mixlib::ShellOut).to \
        receive(:stdout).and_return("s3://#{s3_bucket}/#{s3_prefix}/#{source}_full/2014.10.01.00.00.00")

      chef_run.converge(described_recipe)

      expect(chef_run).to run_bash('download_backup_files').with(
        code: "/usr/bin/s3cmd get -r 's3://#{s3_bucket}/#{s3_prefix}/#{source}_full/2014.10.01.00.00.00' #{tmp_dir}/restore"
      )
    end
  end
end
