require_relative '../spec_helper'

describe 'rails_part::pre_script' do
  let(:chef_run) do
    ChefSpec::Runner.new(
      cookbook_path: ['site-cookbooks', 'cookbooks'],
      platform:      'centos',
      version:       '6.5'
    ) do |node|
      node.set['deploy_rails_puma'] = {
        pre_script: 'echo hogehoge',
        post_script: 'echo foobar'
      }
    end.converge('rails_part::pre_script')
  end

  it 'bash pre_script' do
    expect(chef_run).to ChefSpec::Matchers::ResourceMatcher.new(
      :bash,
      :run,
      'pre_script'
    ).with(
      code: 'echo hogehoge'
    )

    expect(chef_run).to_not ChefSpec::Matchers::ResourceMatcher.new(
      :bash,
      :run,
      'pre_script'
    ).with(
      code: 'echo foobar'
    )
  end
end
