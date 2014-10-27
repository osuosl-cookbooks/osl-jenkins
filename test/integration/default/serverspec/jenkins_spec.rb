require 'spec_helper'

describe service('jenkins') do
  it { should be_running }
end

describe port(8080) do
  it { should be_listening }
end

describe command('curl http://localhost:8080') do
  its(:stdout) { should match /Dashboard \[Jenkins\]/ }
end
