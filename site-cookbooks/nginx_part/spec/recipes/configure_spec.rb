require_relative '../spec_helper'

describe 'nginx_part::configure' do
  describe 'content of the maintenance page is set' do
    let(:chef_run) { ChefSpec::SoloRunner.new }

    nginx_default_root = '/var/www/nginx-default'
    maintenance_page_content = '<!DOCTYPE html><html><head></head><body>dummy</body></html>'

    before do
      chef_run.node.set['nginx']['default_root'] = nginx_default_root
      chef_run.node.set['nginx_part']['maintenance'] = maintenance_page_content
      chef_run.converge(described_recipe)
    end

    it 'create directory of hosting the maintenance page' do
      expect(chef_run).to create_directory("#{nginx_default_root}/maintenance").with(
        user:   'root',
        group:  'root',
        recursive: true
      )
    end

    it 'create maintenance page file' do
      expect(chef_run).to create_file("#{nginx_default_root}/maintenance/index.html").with(
        user:   'root',
        group:  'root',
        content: maintenance_page_content
      )
    end

    it 'delete a nginx default.conf' do
      nginx_dir = '/etc/nginx'
      chef_run.node.set['nginx']['dir'] = nginx_dir
      chef_run.converge(described_recipe)

      expect(chef_run).to delete_file("#{nginx_dir}/conf.d/default.conf")
    end

    it 'create a new default.conf from my template' do
      nginx_dir = '/etc/nginx'
      chef_run.node.set['nginx']['dir'] = nginx_dir
      chef_run.converge(described_recipe)

      expect(chef_run).to create_template("#{nginx_dir}/conf.d/default.conf").with(
        user:  'root',
        group: 'root',
        mode:  '0644',
        variables: {
          maintenance_dir: "#{nginx_default_root}/maintenance"
        }
      )
    end

    it 'restart a nginx service' do
      expect(chef_run).to reload_service('nginx')
    end
  end

  describe 'content of the maintenance page is empty' do
    let(:chef_run) { ChefSpec::SoloRunner.new }

    nginx_default_root = '/var/www/nginx-default'
    maintenance_page_content = nil

    before do
      chef_run.node.set['nginx']['default_root'] = nginx_default_root
      chef_run.node.set['nginx_part']['maintenance'] = maintenance_page_content
      chef_run.converge(described_recipe)
    end

    it 'not create directory of hosting the maintenance page' do
      expect(chef_run).to_not create_directory("#{nginx_default_root}/maintenance")
    end

    it 'not create maintenance page file' do
      expect(chef_run).to_not create_file("#{nginx_default_root}/maintenance/index.html")
    end

    it 'not delete a nginx default.conf' do
      nginx_dir = '/etc/nginx'
      chef_run.node.set['nginx']['dir'] = nginx_dir
      chef_run.converge(described_recipe)

      expect(chef_run).to_not delete_file("#{nginx_dir}/conf.d/default.conf")
    end

    it 'not create a new default.conf from my template' do
      nginx_dir = '/etc/nginx'
      chef_run.node.set['nginx']['dir'] = nginx_dir
      chef_run.converge(described_recipe)

      expect(chef_run).to_not create_template("#{nginx_dir}/conf.d/default.conf")
    end

    it 'not restart a nginx service' do
      expect(chef_run).to_not reload_service('nginx')
    end
  end
end
