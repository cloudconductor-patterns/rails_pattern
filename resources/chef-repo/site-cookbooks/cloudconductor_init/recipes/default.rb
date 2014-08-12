include_recipe 'yum-epel'
include_recipe 'serf'

#install golang
yum_package 'golang' do
    action :install
    options '--enablerepo=epel'
end

yum_package 'mercurial' do

    action :install
end

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

#install event-handler
cookbook_file '/opt/cloudconductor/patterns/event-handler' do
    source 'event-handler'
    mode 0755
end

