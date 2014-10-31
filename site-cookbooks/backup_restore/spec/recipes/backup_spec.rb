require_relative '../spec_helper'

describe 'backup_restore::backup' do
  let(:chef_run) do
    runner = ChefSpec::SoloRunner.new(
      cookbook_path: %w(site-cookbooks cookbooks),
      platform:      'centos',
      version:       '6.5'
    )do |node|
      node.set['backup_restore']['sources']['enabled'] =
       %w(directory mysql ruby)
    end

    runner.converge(described_recipe)
  end

  it 'run directory backup' do
    expect(chef_run).to include_recipe('backup_restore::backup_directory')
  end

  it 'run mysql backup' do
    expect(chef_run).to include_recipe('backup_restore::backup_mysql')
  end

  it 'run ruby backup' do
    expect(chef_run).to include_recipe('backup_restore::backup_ruby')
  end
end
