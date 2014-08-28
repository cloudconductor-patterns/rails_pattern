require_relative '../spec_helper'

describe 'rails_part::create_user' do
  let(:chef_run) do
    ChefSpec::Runner.new(
      cookbook_path:  ['site-cookbooks', 'cookbooks'],
      platform:       'centos',
      version:        '6.5'
    ) do |node|
      node.set['rails_part'] = {
        user: {
          user:         'rails',
          passwd:       '$1$ID1d8IuR$oyeSAB1Z5gHptbJimJ8Fr/',
          manage_home:  true,
          group:        'rails'
        }
      }
    end.converge 'rails_part::create_user'
  end

  it 'create user' do
    expect(chef_run).to create_user('rails').with(
      password: '$1$ID1d8IuR$oyeSAB1Z5gHptbJimJ8Fr/',
      supports: {
        manage_home: true
      }
    )
  end

  it 'create group' do
    expect(chef_run).to create_group('rails').with(
      members: ['rails'],
      append: true
    )
  end
end
