require 'serverspec'

set :backend, :exec

describe file('/etc/haproxy/haproxy.cfg') do
  it { should contain '/etc/pki/tls/wildcard.pem' }
  it { should contain 'maxconn 2000' }
  it { should contain 'backend servers-http' }
  it { should contain 'redirect scheme https' }
  it { should_not contain 'option httpchk' }
end
