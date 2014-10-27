require 'spec_helper'

describe package('httpd') do
  it { should be_installed }
end

describe service('httpd') do
  it { should be_enabled }
  it { should be_running }
end

describe port(80) do
  it { should be_listening }
end

describe port(443) do
  it { should be_listening }
end

describe file('/etc/httpd/sites-available/jenkins_proxy_include.conf') do
    it { should be_file }
    its(:content) { should match /Proxy http:\/\/localhost:8080\/*/ }
end

describe file('/etc/httpd/sites-enabled/test-jenkins.example.org.conf') do
    it { should be_file }
    its(:content) { should_not match 'DocumentRoot' }
    its(:content) { should match /SSLEngine On/ }
    its(:content) { should match /SSLCertificateFile \/etc\/pki\/tls\/certs\/test-jenkins.example.org.pem/ }
    its(:content) { should match /SSLCertificateKeyFile \/etc\/pki\/tls\/private\/test-jenkins.example.org.key/ }
    its(:content) { should match /Redirect Permanent \/ https:\/\/test-jenkins.example.org\// }
    its(:content) { should match /ProxyPreserveHost on/ }
    its(:content) { should match /ProxyPass \/ http:\/\/localhost:8080\// }
    its(:content) { should match /ProxyPassReverse \/ http:\/\/localhost:8080\// }
    its(:content) { should match /ProxyPassReverse \/ https:\/\/test-jenkins.example.org\// }
end

describe host('test-jenkins.example.org') do
    it { should be_resolvable.by('hosts') }
    its(:ipaddress) { should eq '127.0.0.1' }
end

describe command('curl -k -L http://test-jenkins.example.org') do
  its(:stdout) { should match /Dashboard \[Jenkins\]/ }
end

describe command('curl -k -L https://test-jenkins.example.org') do
  its(:stdout) { should match /Dashboard \[Jenkins\]/ }
end
