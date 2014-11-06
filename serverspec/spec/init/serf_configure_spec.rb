require 'spec_helper'

# Chek serf members
describe command('serf members') do
  its(:exit_status) { should eq 0 }
end
