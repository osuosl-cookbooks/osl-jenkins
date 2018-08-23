require 'serverspec'

set :backend, :exec

describe package('chefdk') do
  it { should be_installed }
end

describe command('chef --version') do
  its(:stdout) { should match(/1\.2\.20/) }
end
