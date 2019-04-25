describe package('chefdk') do
  it { should be_installed }
end

describe command('chef --version') do
  its(:stdout) { should match(/2\.5\.3/) }
end
