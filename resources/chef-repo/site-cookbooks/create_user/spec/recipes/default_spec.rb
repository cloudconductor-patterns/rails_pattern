require_relative '../spec_helper'

describe 'create_user::default' do
  let( :chef_run ) do
    chef_run = ChefSpec::Runner.new do |node|
      node.set['create_user'] = {'user' => 'rails',
                                 'passwd' => '$1$ID1d8IuR$oyeSAB1Z5gHptbJimJ8Fr/',
                                 'manage_home' => true,
                                 'group' => 'rails'}

      cookbook_path = ['cookbooks', 'site-cookbooks']
    end.converge 'create_user::default'
  end

  it 'create user' do
    expect(chef_run).to create_user('rails').with(password: '$1$ID1d8IuR$oyeSAB1Z5gHptbJimJ8Fr/')
                                            .with(supports: {:manage_home => true})
  end

  it 'create group' do
    expect(chef_run).to create_group('rails').with(members: ['rails'])
                                             .with(append: true)
  end
end
