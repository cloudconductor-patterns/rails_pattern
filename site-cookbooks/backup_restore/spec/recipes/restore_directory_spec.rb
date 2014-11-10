require_relative '../spec_helper'

describe 'backup_restore::restore_directory' do
  let(:chef_run) { ChefSpec::SoloRunner.new }

  app_name = 'app'
  app_dir = "/var/www/#{app_name}"
  s3_bucket = 'cloudconductor'
  s3_prefix = '/backup'

  before do
    chef_run.node.set['backup_restore']['destinations']['s3'] = {
      bucket: s3_bucket,
      prefix: s3_prefix
    }
    chef_run.node.set['cloudconductor']['applications'] = {
      app_name: {
        type: 'dynamic',
        parameters: {
          backup_directories: app_dir
        }
      }
    }
    chef_run.converge(described_recipe)
  end

  it 'create restore directory' do
    expect(chef_run).to create_directory(app_dir).with(
      recursive: true
    )
  end

  it 'sync backup data from s3' do
    expect(chef_run).to run_bash('sync_from_s3').with(
      code: "s3cmd sync s3://#{s3_bucket}#{s3_prefix}/directories/#{app_name}/ #{app_dir}"
    )
  end
end
