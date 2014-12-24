require_relative '../spec_helper'

describe 'rails_part::configure' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  describe 'enable sasl auth for smtp' do
    before do
      stub_command('/usr/bin/test /etc/alternatives/mta -ef /usr/sbin/sendmail.postfix').and_return(0)

      chef_run.node.set['postfix']['main']['smtp_sasl_auth_enable'] = 'yes'
      chef_run.node.set['postfix']['sasl']['smtp_sasl_passwd'] = 'password'
      chef_run.node.set['postfix']['sasl']['smtp_sasl_user_name'] = 'username'
      chef_run.converge(described_recipe)
    end

    it 'include sasl_auth' do
      expect(chef_run).to include_recipe 'postfix::sasl_auth'
    end
  end

  describe 'disable sasl auth for smtp' do
    before do
      chef_run.node.set['postfix']['main']['smtp_sasl_auth_enable'] = 'no'
      chef_run.converge(described_recipe)
    end

    it 'sasl_auth recipe of postfix cookbook is not include' do
      expect(chef_run).to_not include_recipe 'postfix::sasl_auth'
    end
  end
end
