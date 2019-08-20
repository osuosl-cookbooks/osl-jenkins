RSpec.configure do |config|
  config.before(:all) do
    config.path = '/opt/chef/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end
end

describe package('knife-backup') do
  its('version') { should eq '0.0.10' }
end

describe file('/var/chef-backup-for-rdiff') do
  it { should be_directory }
  its('owner') { should eq 'centos' }
  its('group') { should eq 'centos' }
end
