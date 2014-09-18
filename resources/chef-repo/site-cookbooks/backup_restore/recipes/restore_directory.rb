tmp_dir = "#{node['backup_restore']['tmp_dir']}/restore"
backup_name = 'directory'
backup_file = "#{tmp_dir}/#{backup_name}.tar"

# TODO: Create LWRP

paths = node['backup_restore']['restore']['directory']['paths']
paths.each do |path|
  directory path do
    recursive true
  end
end


bash 'sync_from_s3' do
  s3_dst = node['backup_restore']['destinations']['s3']

  commands = paths.map do |path|
    name = Pathname.new(path).basename
    "s3cmd sync s3://#{s3_dst['bucket']}/#{s3_dst['prefix']}/directories/#{name}/ #{path}"
  end

  code commands.join("\n")
end
