node['backup_restore']['sources']['enabled'].each do |type|
  include_recipe "backup_restore::run_backup_#{type}"
end
