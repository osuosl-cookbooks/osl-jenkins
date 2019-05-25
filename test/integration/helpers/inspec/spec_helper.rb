# -*- encoding : utf-8 -*-

require 'net/http'
require 'open-uri'
require 'uri'

describe command('sudo /opt/chef/embedded/bin/ruby /tmp/jenkin_is_ready.rb') do
  its('exit_status') { should cmp 0 }
end

describe package('java-1.8.0-openjdk') do
  it { should be_installed }
end

describe package('jenkins') do
  its('version') { should eq '2.150.2-1.1' }
end

describe command('yum versionlock') do
  its('stdout') { should match(/^0:jenkins-2.150.2-1.1.x86_64$/) }
end

%w(80 443 8080).each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe command('curl -v http://localhost/ 2>&1') do
  its('stdout') { should match(%r{HTTP/1.1 302 Found}) }
  its('stdout') { should match(%r{Location: https://localhost/}) }
end

describe command('curl -k https://localhost/about/') do
  its('stdout') { should match(/Jenkins 2.150.2/) }
end
