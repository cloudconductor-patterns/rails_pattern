include_recipe 'iptables::disabled'
include_recipe 'yum-epel'

# delete 70-persistent-net.rules extra lines
ruby_block "delete 70-persistent-net.rules extra line" do
  block do
    _file = Chef::Util::FileEdit.new('/etc/udev/rules.d/70-persistent-net.rules')
    _file.search_file_replace_line('^SUBSYSTEM.*', '')
    _file.search_file_replace_line('^# PCI device .*', '')
    _file.write_file
  end
  only_if {File.exist?('/etc/udev/rules.d/70-persistent-net.rules')}
end

include_recipe 'serf'

# override template
r = resources(template: '/etc/init.d/serf')
r.cookbook 'cloudconductor_init'

# install golang
yum_package 'golang' do
    action :install
    options '--enablerepo=epel'
end

# install mercurial
yum_package 'mercurial' do
    action :install
end

# install pluginhook
git '/opt/cloudconductor/temp/pluginhook' do
    repository 'https://github.com/progrium/pluginhook.git'
    revision "master"
    action :export
end

bash 'install pluginhook' do
    environment 'GOPATH' => '/usr/local/golang'
    cwd         '/opt/cloudconductor/temp/pluginhook'
    code <<-EOH
        go get code.google.com/p/go.crypto/ssh/terminal
        go build -o /usr/local/bin/pluginhook
    EOH
    creates '/usr/local/bin/pluginhook'
end

# install event-handler
cookbook_file node['serf']['agent']['event_handlers'].first do
    source 'event-handler'
    mode 0755
end

include_recipe 'consul::install_binary'

# override Consul service template
r = resources(template: '/etc/init.d/consul')
r.cookbook 'cloudconductor_init'
