::Chef::Recipe.send(:include, BackupRubyHelper)
::Chef::Resource.send(:include, BackupRubyHelper)

tmp_dir = "#{node['backup_restore']['tmp_dir']}/restore"
backup_name = 'ruby_full'
backup_file = "#{tmp_dir}/#{backup_name}.tar"

# TODO: Create LWRP
applications = node['cloudconductor']['applications'].select(&dynamic?)

directory node['rails_part']['app']['base_path'] do
  recursive true
end

bash 'extract_full_backup' do
  code <<-EOF
    tar -xvf #{backup_file} -C #{tmp_dir}
    tar -zxvf #{tmp_dir}/#{backup_name}/archives/ruby.tar.gz -C #{node['rails_part']['app']['base_path']}
  EOF
  only_if { ::File.exist?(backup_file) && !::Dir.exist?("#{tmp_dir}/#{backup_name}") }
end

ruby_block 'link_to_latest_version' do
  block do
    applications.keys.each do |name|
      path = Pathname.new("#{node['rails_part']['app']['base_path']}/#{name}")
      next if (path + 'current').exist?
      next unless (path + 'releases').exist?

      latest = (path + 'releases').children.last
      (path + 'current').make_symlink(latest) if latest.exist?
    end
  end
end
