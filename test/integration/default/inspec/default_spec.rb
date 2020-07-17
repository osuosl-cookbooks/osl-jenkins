describe package('java-1.8.0-openjdk') do
  it { should be_installed }
end

describe group('alfred') do
  it { should exist }
  its('gid') { should eq 10000 }
end

describe user('alfred') do
  it { should exist }
  its('group') { should eq 'alfred' }
  its('shell') { should eq '/bin/bash' }
  its('home') { should eq '/home/alfred' }
  its('uid') { should eq 10000 }
end

describe file('/home/alfred/.ssh/authorized_keys') do
  it { should be_file }
  its('mode') { should cmp 0600 }
  its('owner') { should eq 'alfred' }
  its('group') { should eq 'root' }
end
