describe package('java-1.8.0-openjdk') do
  it { should be_installed }
end

describe group('alfred') do
  it { should exist }
  its('gid') { should eq 10000 }
end
