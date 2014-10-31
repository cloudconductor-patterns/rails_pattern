require 'spec_helper'

# Chek serf members
describe command('serf members') do
  it { should return_exit_status 0 }
end
