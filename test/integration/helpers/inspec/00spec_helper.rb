chef_installed = inspec.file('/opt/chef/bin/chef-client').exist?
chef = chef_installed ? 'chef' : 'cinc'

describe command("/opt/#{chef}/embedded/bin/ruby /tmp/jenkin_is_ready.rb") do
  its('exit_status') { should cmp 0 }
end

describe package('java-11-openjdk') do
  it { should be_installed }
end

describe package('jenkins') do
  it { should be_installed }
end

%w(80 443 8080).each do |p|
  describe port(p) do
    it { should be_listening }
  end
end

describe http('http://127.0.0.1/') do
  its('status') { should eq 302 }
  its('headers.Location') { should match(%r{https://127.0.0.1/}) }
end

# describe http('https://127.0.0.1/about/', ssl_verify: false) do
#   its('body') { should match(/Jenkins 2.289.1/) }
# end
