tmp_dir = "#{node['backup_restore']['tmp_dir']}/restore"
backup_name = 'directory'
backup_file = "#{tmp_dir}/#{backup_name}.tar"

# TODO: Create LWRP

def dynamic?
  -> (_, application) { application[:type] == 'dynamic' }
end

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
  s3_dst = node['backup_restore']['destinations']['s3']

  commands = paths.flatten.map do |path|
    name = Pathname.new(path).basename
    "s3cmd sync s3://#{s3_dst['bucket']}/#{s3_dst['prefix']}/directories/#{name}/ #{path}"
  end

  code commands.join("\n")
end
