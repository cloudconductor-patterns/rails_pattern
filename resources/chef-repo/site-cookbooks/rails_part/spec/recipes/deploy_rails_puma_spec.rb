require_relative '../spec_helper'

describe 'rails_part::deploy_rails_puma' do
  let(:chef_run) do
    ChefSpec::Runner.new(
      cookbook_path: ['site-cookbooks', 'cookbooks'],
      platform:      'centos',
      version:       '6.5'
    ).converge('rails_part::deploy_rails_puma')
  end

  it 'include recipe git' do
    expect(chef_run).to include_recipe 'git::default'
  end

  it 'include recipe build-essential:[platform_family]' do
    expect(chef_run).to include_recipe 'build-essential::_rhel'
  end

  it 'include recipe pre_script' do
    expect(chef_run).to include_recipe 'rails_part::pre_script'
  end

  it 'deploy rails application' do

    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(:application, :deploy, 'app').with(
      path:       '/var/www/app',
      owner:      'rails',
      group:      'rails',
      repository: 'http://172.0.0.1/app.git',
      revision:   'HEAD',
      migrate:    true,
      migration_command: '/opt/rbenv/shims/bundle exec rake db:migrate RAILS_ENV=production'
    )
  end

  it 'create init.d file of puma' do
    expect(chef_run).to create_template('/etc/init.d/app').with(
      source: 'puma.erb',
      owner:  'root',
      group:  'root',
      mode:   '0755'
    )
  end

  it 'add puma service' do
    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(:bash, :run, 'add_puma_service').with(
      code: 'chkconfig --add app'
    )
  end

  it 'start puma service' do
    expect(chef_run).to start_service('app')
  end

  it 'include recipe post_script' do
    expect(chef_run).to include_recipe 'rails_part::post_script'
  end

end
