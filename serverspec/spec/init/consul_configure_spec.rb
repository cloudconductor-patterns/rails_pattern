require 'spec_helper'

# Check consul members
describe command('consul members') do
  its(:exit_status) { should sq 0 }
end

# Check consul KeyValueStore
# Value Check
describe command('curl -X GET --noproxy localhost http://localhost:8500/v1/kv/cloudconductor/parameters | grep Value | wc -l') do
  its(:stdout) { should eq '1' }
end
