describe package('cinc-workstation') do
  it { should be_installed }
end

describe command('cinc --version') do
  its('exit_status') { should eq 0 }
end
