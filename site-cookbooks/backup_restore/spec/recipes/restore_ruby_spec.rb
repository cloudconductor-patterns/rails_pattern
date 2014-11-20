require_relative '../spec_helper'

describe 'backup_restore::restore_ruby' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  it 'create application directory' do
    base_path = '/var/www'
    chef_run.node.set['rails_part']['app']['base_path'] = base_path
    chef_run.converge(described_recipe)

    expect(chef_run).to create_directory(base_path).with(
      recursive: true
    )
  end

  describe 'backup file is exist and is not yet uncompress' do
    it 'extract_full_backup' do
      tmp_dir = '/tmp'
      chef_run.node.set['backup_restore']['tmp_dir'] = tmp_dir
      allow(::File).to receive(:exist?).and_call_original
      allow(::File).to receive(:exist?).with("#{tmp_dir}/restore/ruby_full.tar").and_return(true)
      allow(::Dir).to receive(:exist?).and_call_original
      allow(::Dir).to receive(:exist?).with("#{tmp_dir}/restore/ruby_full").and_return(false)
      chef_run.converge(described_recipe)

      expect(chef_run).to run_bash('extract_full_backup')
    end
  end

  it 'create link to latest version' do
    chef_run.converge(described_recipe)
    expect(chef_run).to run_ruby_block('link_to_latest_version')
  end
end
