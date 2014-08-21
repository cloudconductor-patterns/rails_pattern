require_relative '../spec_helper'

describe 'iptables-disabled::default' do
  #let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }
  let( :chef_run ) do
    chef_run = ChefSpec::Runner.new do |node|
      cookbook_path = ['cookbooks', 'site-cookbooks']
    end.converge 'iptables-disabled::default'
  end

  it 'disabled a iptables' do
    expect(chef_run).to disable_service('iptables')
  end

  it 'disabled a ip6tables' do
    expect(chef_run).to disable_service('ip6tables')
  end
end
