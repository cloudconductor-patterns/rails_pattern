require 'spec_helper'

# Check listen port
describe port(3306) do
  it { should be_listening.with('tcp') }
end

# Check mysql databases for consul kvs
describe 'there is a the assumed key to consul_parameters' do
  params = property[:consul_parameters]

  if params[:mysql_part] && params[:mysql_part][:app] && params[:mysql_part][:app][:database]
    database = params[:mysql_part][:app][:database]
  else
    database = 'rails'
  end

  if params[:mysql_part] && params[:mysql_part][:app] && params[:mysql_part][:app][:username]
    username = params[:mysql_part][:app][:username]
  else
    username = 'rails'
  end

  if params[:mysql_part] && params[:mysql_part][:app] && params[:mysql_part][:app][:password]
    password = params[:mysql_part][:app][:password]
  else
    password = 'todo_replace_randompassword'
  end

  describe command("mysql #{database} -u #{username} -p#{password} -e 'SHOW DATABASES;'") do
    its(:exit_status) { should eq 0 }
  end
end
