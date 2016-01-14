require 'spec_helper'
require 'json'

describe 'web_deploy' do
  chef_run = ChefSpec::SoloRunner.new

  before do
    chef_run.node.normal_attrs = property[:chef_attributes]
    chef_run.converge('role[web_deploy]')
  end

  it 'is delete nginx default.conf' do
    expect(file("#{chef_run.node['nginx']['dir']}/conf.d/default.conf")).to_not exist
  end

  describe 'each applications' do
    chef_run.node.normal_attrs = property[:chef_attributes]
    chef_run.converge('role[web_deploy]')

    chef_run.node['cloudconductor']['applications'].each do |app_name, app|
      it "is create temp directory of application" do
        expect(file("#{chef_run.node['nginx_part']['tmp_dir']}/#{app_name}")).to exist
      end

      it "is create application root directory of application" do
        expect(file("#{chef_run.node['nginx']['default_root']}/#{app_name}/#{app['version']}")).to exist
      end

      it "is create conf file" do
        expect(file("#{chef_run.node['nginx']['dir']}/sites-available/#{app_name}"))
          .to be_file
          .and be_mode(755)
          .and be_owned_by(chef_run.node['nginx']['user'])
          .and be_grouped_into(
            chef_run.node['nginx']['group'] == chef_run.node['nginx']['user'] ? 'root' : chef_run.node['nginx']['group']
          )
      end

      it "is sites-enabled conf link to sites-available conf" do
        expect(file("#{chef_run.node['nginx']['dir']}/sites-enabled/#{app_name}"))
          .to be_linked_to("#{chef_run.node['nginx']['dir']}/sites-available/#{app_name}")
      end

      it "is current root link to application root" do
        expect(file("#{chef_run.node['nginx']['default_root']}/#{app_name}/current"))
         .to be_linked_to("#{chef_run.node['nginx']['default_root']}/#{app_name}/#{app['version']}")
      end
    end
  end

  it 'apache service is running' do
    expect(service('nginx')).to be_running
  end
end
