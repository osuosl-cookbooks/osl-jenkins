require 'spec_helper'

set :backend, :exec

describe 'master' do
  it_behaves_like 'jenkins_server'
end

describe command('curl -k https://127.0.0.1/credential-store/domain/_/') do
  its(:stdout) { should match(/alfred \(Credentials for alfred - created by Chef\)/) }
end
