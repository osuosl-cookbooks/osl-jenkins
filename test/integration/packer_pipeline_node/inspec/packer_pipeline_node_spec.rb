describe file('/home/alfred/.gitconfig') do
  it { should exist }
  it { should be_a_file }
  its('content') do
    should match(%r{\[alias\]\n\s*pr\s*=\s"!f\(\)\s\{\sgit\sfetch\s-fu\s\$\{2:-\$\(git\sremote\s\|\
grep\s\^upstream\s\|\|\secho\sorigin\)\}\srefs\/pull\/\$1\/head:pr\/\$1\s&&\sgit\s\
checkout\spr\/\$1;\s\};\sf"})
  end
end

describe file('/home/alfred/workspace') do
  it { should be_a_directory }
  it { should exist }
  its('owner') { should eq 'alfred' }
  its('group') { should eq 'alfred' }
end

describe file('/home/alfred/.ssh/packer_alfred_id') do
  it { should be_a_file }
  its('owner') { should eq 'alfred' }
  its('group') { should eq 'alfred' }
  its('mode') { should cmp 0600 }
end

describe file('/home/alfred/.ssh/packer_alfred_id.pub') do
  it { should be_a_file }
  its('owner') { should eq 'alfred' }
  its('group') { should eq 'alfred' }
  its('mode') { should cmp 0600 }
end

describe file('/home/alfred/openstack_credentials.json') do
  it { should be_a_file }
  its('owner') { should eq 'alfred' }
  its('group') { should eq 'alfred' }
  its('mode') { should cmp 0600 }
end

describe file('/home/alfred/openstack_credentials.json') do
  it { should be_a_file }
  its('owner') { should eq 'alfred' }
  its('group') { should eq 'alfred' }
  its('mode') { should cmp 0600 }
end

describe file('/opt/chef/embedded/bin/openstack_taster') do
  it { should be_a_file }
  it { should be_executable }
end

describe command('berks version') do
  its('exit_status') { should eq 0 }
end

describe command('/usr/local/bin/openstack --version') do
  its('exit_status') { should eq 0 }
end

describe file('/home/alfred/.git-credentials') do
  it { should be_a_file }
  its('content') { should match('https://osuosl-manatee:FAKE_TOKEN@github.com') }
end
