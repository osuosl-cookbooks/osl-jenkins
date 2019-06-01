describe package('haproxy') do
  it { should be_installed }
end

describe file('/etc/haproxy/haproxy.cfg') do
  its('content') { should match(%r{/etc/pki/tls/wildcard.pem'} }
  its('content') { should match(/maxconn 2000/) }
  its('content') { should match(/backend servers-http/) }
  its('content') { should match(/redirect scheme https/) }
  its('content') { should_not match(/option httpchk/) }
end
