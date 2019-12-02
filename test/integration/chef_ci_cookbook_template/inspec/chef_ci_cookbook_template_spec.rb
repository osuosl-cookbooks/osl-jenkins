describe package('chefdk') do
  it { should be_installed }
end

describe command('chef --version') do
  its('stdout') { should match(/3\.12\.15\.1/) }
end
