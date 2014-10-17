require_relative '../spec_helper'

describe 'rails_part::configure' do
  let(:chef_run) do
    runner = ChefSpec::Runner.new(
      cookbook_path: ['site-cookbooks', 'cookbooks'],
      platform:      'centos',
      version:       '6.5'
    )do |node|
      node.set['postfix']['sasl'] = 'foo',
      node.set['postfix']['sasl_password_file'] = '/etc/postfix/sasl_passwd'
    end
    runner.converge('rails_part::configure')
  end

  before do
    stub_command('/usr/bin/test /etc/alternatives/mta -ef /usr/sbin/sendmail.postfix').and_return(0)
  end

  it 'include sasl_auth' do
    expect(chef_run).to include_recipe 'postfix::sasl_auth'
  end
end
