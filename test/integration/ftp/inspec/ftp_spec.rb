describe file '/etc/sudoers.d/alfred' do
  it { should be_file }
  its('content') { should match %r{NOPASSWD:/data/mirror/bin/run-update} }
end
