chef_installed = inspec.file('opt/chef/bin/chef-client').exist?
chef = chef_installed ? 'chef' : 'cinc'

describe command("/opt/#{chef}/embedded/bin/gem list") do
  its('stdout') { should match(/knife-backup\s\(0.0.10\)/) }
end

describe file('/var/chef-backup-for-rdiff') do
  it { should be_directory }
  its('owner') { should eq 'centos' }
  its('group') { should eq 'centos' }
end
