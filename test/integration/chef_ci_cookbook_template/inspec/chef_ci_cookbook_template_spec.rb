describe package('cinc-workstation') do
  it { should be_installed }
end

describe command('chef --version') do
  its('stdout') { should match(/20\.9\.158/) }
end
