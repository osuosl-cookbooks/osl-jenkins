require 'serverspec'

set :backend, :exec

describe package('java-1.8.0-openjdk') do
  it { should be_installed }
end

describe package('jenkins') do
  it { should be_installed.with_version('1.654-1.1') }
end

%w(80 443 8080).each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
