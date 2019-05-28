describe command('/opt/chef/embedded/bin/ruby /tmp/jenkin_is_ready.rb') do
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

# describe command('curl -v http://localhost/ 2>&1') do
#   its('stdout') { should match(%r{HTTP/1.1 302 Found}) }
#   its('stdout') { should match(%r{Location: https://localhost/}) }
# end

describe http('http://localhost/', 
              enable_remote_worker: true) do
  its('status') { should cmp 302 }
  its('headers.Location') { should eq 'https://localhost/' }
end

# describe command('curl -k https://localhost/about/') do
#   its('stdout') { should match(/Jenkins 2.150.2/) }
# end

describe http('https://localhost/about/', 
              enable_remote_worker: true,
              ssl_verify: false) do
  its('body') { should match(/Jenkins 2.150.2/) }
end
