tmp_dir = "#{node['backup_restore']['tmp_dir']}/restore"
full_backup_name = 'ruby_full'
backup_file = "#{tmp_dir}/#{full_backup_name}.tar"

# TODO: Create LWRP

bash 'extract_full_backup' do
  code <<-EOF
    tar -xvf #{backup_file} -C #{tmp_dir}
    tar -zxvf #{tmp_dir}/#{full_backup_name}/archives/ruby.tar.gz -C /
  EOF
  only_if { ::File.exist?(backup_file) && !::Dir.exist?("#{tmp_dir}/#{full_backup_name}") }
end
