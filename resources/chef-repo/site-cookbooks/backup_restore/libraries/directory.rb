module BackupDirectoryHelper
  def dynamic?
    -> (_, application) { application[:type] == 'dynamic' }
  end

  def syncer_definition
    s3_dst = node['backup_restore']['destinations']['s3']
    paths = node['backup_restore']['sources']['directory']['paths']

    commands paths.map do |path|
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
