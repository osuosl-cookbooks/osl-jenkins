require 'serverspec'

set :backend, :exec

describe 'master' do
  it_behaves_like 'jenkins_server'
end
