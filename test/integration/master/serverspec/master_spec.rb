require 'serverspec'

set :backend, :exec

describe package('jenkins') do
  it { should be_installed.with_version('1.643-1.1') }
end

describe port('8080') do
  it { should be_listening }
end
