require_relative '../spec_helper'
require_relative '../../libraries/helper'

describe do
  before do
    @helper = Object.new
    @helper.extend NginxHelper
    node = {
      'cloudconductor' => {
        'servers' => {
          'ap1' => { 'roles' => 'ap', 'private_ip' => '127.0.0.1' },
          'ap2' => { 'roles' => 'ap', 'private_ip' => '127.0.0.2' },
          'db' => { 'roles' => 'db', 'private_ip' => '127.0.0.3' }
        }
      }
    }
    allow(@helper).to receive(:node).and_return(node)
  end

  describe '#ap_servers' do
    it 'return ap role hash' do
      expect(@helper.ap_servers).to eq(
        'ap1' => { 'roles' => 'ap', 'private_ip' => '127.0.0.1' },
        'ap2' => { 'roles' => 'ap', 'private_ip' => '127.0.0.2' }
      )
    end
  end

  describe '#first_ap_server' do
    it 'return first ap role hash values' do
      expect(@helper.first_ap_server).to eq(
        'roles' => 'ap', 'private_ip' => '127.0.0.1'
      )
    end
  end
end
