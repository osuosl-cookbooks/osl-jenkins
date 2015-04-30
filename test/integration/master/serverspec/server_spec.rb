require 'serverspec'

set :backend, :exec

describe package('jenkins') do
  it { should be_installed.with_version('1.608-1.1') }
end

describe port('8080') do
  it { should be_listening }
end

describe file('/var/lib/jenkins/plugins/build-token-root.jpi') do
  it { should be_file }
end

describe file('/var/lib/jenkins/plugins/credentials.jpi') do
  it { should be_file }
end

describe file('/var/lib/jenkins/plugins/credentials-binding.jpi') do
  it { should be_file }
end
