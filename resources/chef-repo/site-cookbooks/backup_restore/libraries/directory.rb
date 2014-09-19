module BackupDirectoryHelper
  def dynamic?
    -> (_, application) { application[:type] == 'dynamic' }
  end

  def syncer_definition
    applications = node['cloudconductor']['applications']
    paths = applications.select(&dynamic?).map do |_, application|
      application[:parameters][:backup_directories] || []
    end

    s3_dst = node['backup_restore']['destinations']['s3']

    commands = paths.flatten.map do |path|
      "`s3cmd sync #{path} s3://#{s3_dst['bucket']}/#{s3_dst['prefix']}/directories/`"
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
