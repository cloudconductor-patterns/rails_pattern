require_relative '../spec_helper'

describe 'nginx_part::configure' do
  describe 'if node["nginx_part"]["maintenance"] is present' do
    let(:chef_run) do
      ChefSpec::Runner.new(cookbook_path: ['site-cookbooks', 'cookbooks'], platform: 'centos', version: '6.5') do |node|
        node.set['nginx_part']['maintenance'] = "<!DOCTYPE html><html><head></head><body>dummy</body></html>"
        node.set['nginx']['dir'] = '/etc/nginx'
        node.set['nginx']['default_root'] = '/var/www/nginx-default'
      end
    end

    it 'create anginx maintenance directory with attributes' do
      chef_run.converge(described_recipe)
      expect(chef_run).to create_directory('/var/www/nginx-default/maintenance').with(
        user:   'root',
        group:  'root',
        recursive: true
      )
    end

    it 'creates a nginx index.html with attributes' do
      chef_run.converge(described_recipe)
      expect(chef_run).to create_file('/var/www/nginx-default/maintenance/index.html').with(
        user:   'root',
        group:  'root'
      )
    end

    it 'deletes a nginx default.conf with an explicit action' do
      chef_run.converge(described_recipe)
      expect(chef_run).to delete_file('/etc/nginx/conf.d/default.conf')
    end

    it 'creates a nginx default.conf with attributes' do
      chef_run.converge(described_recipe)
      expect(chef_run).to create_template('/etc/nginx/conf.d/default.conf').with(
        user:  'root',
        group: 'root',
        mode:  '0644'
      )
    end

    it 'restarts a service with a nginx' do
      chef_run.converge(described_recipe)
      expect(chef_run).to reload_service('nginx')
    end
  end

  describe 'if node["nginx_part"]["maintenance"] is not present' do
    let(:chef_run) do
      ChefSpec::Runner.new(
        cookbook_path: ['site-cookbooks', 'cookbooks'],
        platform:      'centos',
        version:       '6.5').converge(described_recipe)
    end

    it 'create anginx maintenance directory with attributes' do
      expect(chef_run).to_not create_directory('/var/www/nginx-default/maintenance')
    end

    it 'not creates a nginx index.html with attributes' do
      expect(chef_run).to_not create_file('/var/www/nginx-default/maintenance/index.html')
    end

    it 'not deletes a nginx default.conf with an explicit action' do
      expect(chef_run).to_not delete_file('/etc/nginx/conf.d/default.conf')
    end

    it 'not creates a nginx default.conf with attributes' do
      expect(chef_run).to_not create_template('/etc/nginx/conf.d/default.conf')
    end

    it 'not restarts a service with a nginx' do
      expect(chef_run).to_not reload_service('nginx')
    end
  end
end
