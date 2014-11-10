require_relative '../spec_helper'

describe 'backup_restore::setup' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'include cron' do
    expect(chef_run).to include_recipe 'cron::default'
  end

  it 'install backup gem' do
    expect(chef_run).to install_gem_package('backup').with(
      version: nil,
      options: '--no-ri --no-rdoc'
    )
  end

  it 'include backup' do
    expect(chef_run).to include_recipe 'backup::default'
  end

  it 'include percona' do
    expect(chef_run).to include_recipe 'percona::backup'
  end

  it 'create a link to backup directory' do
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:exist?).with('/root/.chefdk/gem/ruby/2.1.0/bin/backup').and_return(true)

    expect(chef_run.link('/usr/local/bin/backup')).to link_to('/root/.chefdk/gem/ruby/2.1.0/bin/backup')
  end

  it 'include yum-epel' do
    expect(chef_run).to include_recipe 'yum-epel::default'
  end

  it 'include s3cmd-master' do
    expect(chef_run).to include_recipe 's3cmd-master::default'
  end

  it 'install python-dateutil' do
    expect(chef_run).to install_package 'python-dateutil'
  end

  describe 'gem version is specified' do
    it 'install the specified version gem' do
      chef_run.node.set['backup']['version'] = '4.1.0'
      chef_run.converge(described_recipe)
      expect(chef_run).to install_gem_package('backup').with(
        version: '4.1.0',
        options: '--no-ri --no-rdoc'
      )
    end
  end

  describe 'backup gem is upgrade' do
    before do
      chef_run.node.set['backup']['upgrade?'] = 'true'
      chef_run.converge(described_recipe)
    end
    it 'upgrace backup gem' do
      expect(chef_run).to upgrade_gem_package('backup').with(
        version: nil,
        options: '--no-ri --no-rdoc'
      )
    end
  end

  describe 'backup directry is not exist' do
    it 'not create a link to backup directory' do
      allow(::File).to receive(:exist?).and_call_original
      allow(::File).to receive(:exist?).with('/root/.chefdk/gem/ruby/2.1.0/bin/backup').and_return(false)

      expect(chef_run.link('/usr/local/bin/backup')).to_not link_to('/root/.chefdk/gem/ruby/2.1.0/bin/backup')
    end
  end
end
