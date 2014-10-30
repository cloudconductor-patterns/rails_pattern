require_relative '../spec_helper'

describe 'backup_restore::restore_ruby' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      cookbook_path: %w(site-cookbooks cookbooks),
      platform:      'centos',
      version:       '6.5'
    ) do |node|
      node.set['cloudconductor']['applications'] = {
        dynamic_git_app: {
          type: 'dynamic',
          parameters: {
            backup_directories: '/var/www/app'
          }
        }
      }
    end
    runner.converge(described_recipe)
  end

  tmp_dir = '/tmp/backup/restore'
  backup_name = 'ruby_full'
  backup_file = "#{tmp_dir}/#{backup_name}.tar"

  it 'create base_path' do
    expect(chef_run).to create_directory('/var/www').with(
      recursive: true
    )
  end

  it 'extract_full_backup' do
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:exist?).with(backup_file).and_return(true)
    allow(::Dir).to receive(:exist?).and_call_original
    allow(::Dir).to receive(:exist?).with("#{tmp_dir}/#{backup_name}").and_return(false)
    expect(chef_run).to run_bash('extract_full_backup').with(
      code: <<-EOF
    tar -xvf #{backup_file} -C #{tmp_dir}
    tar -zxvf #{tmp_dir}/#{backup_name}/archives/ruby.tar.gz -C #{chef_run.node['rails_part']['app']['base_path']}
  EOF
    )
  end

  it 'link_to_latest_version' do
    expect(chef_run).to run_ruby_block('link_to_latest_version')
  end
end
