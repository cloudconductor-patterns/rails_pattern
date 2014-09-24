::Chef::Recipe.send(:include, BackupCommonHelper)

# TODO: Create LWRP

applications = node['cloudconductor']['applications']
paths = applications.select(&dynamic?).map do |_, application|
  application[:parameters][:backup_directories] || []
end

paths.flatten.each do |path|
  directory path do
    recursive true
  end
end

bash 'sync_from_s3' do
  code restore_code
end
