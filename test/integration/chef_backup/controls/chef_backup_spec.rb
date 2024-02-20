control 'chef_backup' do
  describe command '/opt/cinc/embedded/bin/gem list' do
    its('stdout') { should match(/knife-backup\s\(0.0.10\)/) }
  end

  describe file('/var/chef-backup-for-rdiff') do
    it { should be_directory }
    its('owner') { should eq 'jenkins' }
    its('group') { should eq 'jenkins' }
  end
end
