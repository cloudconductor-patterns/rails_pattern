module BackupMySQLHelper
  include BackupCommonHelper

  def import_stores(incremental = false)
    blocks = node['backup_restore']['destinations']['enabled'].map do |destination_type|
      case destination_type
      when 's3'
        incremental ? store_with_s3_incremental : store_with_s3_full
      end
    end
    blocks.join('\n\n')
  end

  def lsn_dir
    "#{node['backup_restore']['tmp_dir']}/mysql/lsn_dir"
  end

  def latest_full_backup
    "#{lsn_dir}/latest_full_backup_path"
  end

  private

  def store_with_s3_full
    s3_dst = node['backup_restore']['destinations']['s3']
    %(
      store_with S3 do |s3|
        s3.bucket = "#{s3_dst['bucket']}"
        s3.region = "#{s3_dst['region']}"
        s3.access_key_id = "#{s3_dst['access_key_id']}"
        s3.secret_access_key = "#{s3_dst['secret_access_key']}"
        s3.path = "#{s3_dst['prefix']}"
        s3.max_retries = 2
        s3.retry_waitsec = 10
      end
    )
  end

  def store_with_s3_incremental
    s3_dst = node['backup_restore']['destinations']['s3']
    %(
      backup_path = File.exists?("#{latest_full_backup}") ? File.read("#{latest_full_backup}") : "#{s3_dst['prefix']}"
      store_with S3 do |s3|
        s3.bucket = "#{s3_dst['bucket']}"
        s3.region = "#{s3_dst['region']}"
        s3.access_key_id = "#{s3_dst['access_key_id']}"
        s3.secret_access_key = "#{s3_dst['secret_access_key']}"
        s3.path = backup_path
        s3.max_retries = 2
        s3.retry_waitsec = 10
      end
    )
  end
end
