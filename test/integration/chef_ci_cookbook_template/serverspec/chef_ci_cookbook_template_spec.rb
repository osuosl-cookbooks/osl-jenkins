require 'serverspec'

set :backend, :exec

describe package('chefdk') do
  it { should be_installed }
end

describe command('foodcritic --version') do
  its(:stdout) { should match(/foodcritic 4.0.0/) }
end

describe command('rubocop --version') do
  its(:stdout) { should match(/0.28.0/) }
end
