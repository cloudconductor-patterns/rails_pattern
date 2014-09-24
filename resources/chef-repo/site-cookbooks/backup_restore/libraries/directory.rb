module BackupDirectoryHelper
  include BackupCommonHelper

  def backup_directories
    applications = node['cloudconductor']['applications']
    paths = applications.select(&dynamic?).map do |_, application|
      application[:parameters][:backup_directories] || []
    end

    paths.flatten
  end

  def s3_uri(name)
    s3 = node['backup_restore']['destinations']['s3']
    URI.join("s3://#{s3['bucket']}", File.join(s3['prefix'], 'directories', name, '/')).to_s
  end

  def syncer_definition
    commands = backup_directories.map do |path|
      name = Pathname.new(path).basename
      "`s3cmd sync #{path} #{s3_uri(name)}`"
    end

    commands.join("\n")
  end

  def restore_code
    commands = backup_directories.map do |path|
      name = Pathname.new(path).basename
      "s3cmd sync #{s3_uri(name)} #{path}"
    end

    commands.join("\n")
  end

  def parse_schedule
    schedule = node['backup_restore']['sources']['directory']['schedule']
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
