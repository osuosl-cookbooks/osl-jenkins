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

describe command('curl -k -L http://test-jenkins.example.org') do
  its(:stdout) { should match /Dashboard \[Jenkins\]/ }
end

describe command('curl -k -L https://test-jenkins.example.org') do
  its(:stdout) { should match /Dashboard \[Jenkins\]/ }
end
