require 'spec_helper'

# Check serf members
describe command('serf members') do
  its(:exit_status) { should eq 0 }
end
