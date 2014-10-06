require 'spec_helper'

# Check consul members
describe command('consul members') do
  it { should return_exit_status 0 }
end

# Check consul KeyValueStore
# Value Check
describe command('curl -X GET --noproxy localhost http://localhost:8500/v1/kv/cloudconductor/parameters | grep Value | wc -l') do
  it { should return_stdout '1' }
end
