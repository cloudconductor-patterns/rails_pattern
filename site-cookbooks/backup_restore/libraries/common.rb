module BackupCommonHelper
  def dynamic?
    -> (_, application) { application[:type] == 'dynamic' }
  end
end
