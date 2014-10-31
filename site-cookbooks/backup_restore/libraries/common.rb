module BackupCommonHelper
  def dynamic?
    -> (_, application) { application[:type] == 'dynamic' }
  end

  def parse_schedule(schedule)
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
