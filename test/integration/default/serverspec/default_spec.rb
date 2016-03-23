require 'serverspec'

set :backend, :exec

describe package('java-1.7.0-openjdk') do
  it { should be_installed }
end

describe group('alfred') do
  it { should exist }
end

describe user('alfred') do
  it { should exist }
  it { should belong_to_group 'alfred' }
  it { should have_login_shell '/bin/bash' }
  it { should have_home_directory '/home/alfred' }
end

describe file('/home/alfred/.ssh/authorized_keys') do
  it { should be_file }
  it { should be_mode 600 }
  it { should be_owned_by 'alfred' }
  it { should be_grouped_into 'alfred' }
end
