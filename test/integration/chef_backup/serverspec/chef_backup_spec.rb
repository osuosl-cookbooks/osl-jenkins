RSpec.configure do |config|
  config.before(:all) do
    config.path = '/opt/chef/embedded/bin:/usr/local/sbin:
                   /usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end
end

describe package('knife-backup') do
  it { should be_installed.by('gem').with_version('0.0.10') }
end

describe file('/var/chef-backup-for-rdiff') do
  it { should be_directory }
  it { should be_owned_by 'centos' }
  it { should be_grouped_into 'centos' }
end
