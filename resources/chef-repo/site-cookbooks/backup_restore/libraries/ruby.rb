module BackupRubyHelper
  def application_paths
    applications = node['cloudconductor']['applications']
    dynamic_applications = applications.select { |_, application| application[:type] == 'dynamic' }
    dynamic_applications.keys.map { |name| "archive.add '#{node['rails_part']['app']['base_path']}/#{name}/current'" }.join('\n')
  end
end
