require 'spec_helper'

param = property[:consul_parameters]

if param[:rails_part] && param[:rails_part][:puma] && param[:rails_part][:puma][:bind]
  bind = param[:rails_part][:puma][:bind]
  port = bind[bind.rindex(":")+1, bind.length]

  describe port(port) do
    it { should be_listening.with('tcp') }
  end
else
  describe port(8080) do
    it { should be_listening.with('tcp') }
  end
end
