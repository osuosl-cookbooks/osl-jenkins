require 'serverspec'

set :backend, :exec

describe file('/var/lib/jenkins/plugins/build-token-root.jpi') do
  it { should be_file }
end

describe file('/var/lib/jenkins/plugins/credentials.jpi') do
  it { should be_file }
end

describe file('/var/lib/jenkins/plugins/credentials-binding.jpi') do
  it { should be_file }
end
