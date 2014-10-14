module BackupRubyHelper
  include BackupCommonHelper

  def application_paths
    applications = node['cloudconductor']['applications']
    paths = applications.select(&dynamic?).keys.map do |name|
      begin
        realpath = Pathname.new("#{node['rails_part']['app']['base_path']}/#{name}/current").realpath
        realpath.relative_path_from Pathname.new(node['rails_part']['app']['base_path'])
      rescue Errno::ENOENT
        nil
      end
    end

    paths.compact.map { |path| "archive.add '#{path}'" }.join("\n")
  end

  def parse_schedule(type)
    schedule = node['backup_restore']['sources']['ruby']['schedule'][type]
    minute, hour, day, month, week = schedule.split
    {
      minute: minute,
      hour: hour,
      day: day,
      month: month,
      weekday: week
    }
  end
end
