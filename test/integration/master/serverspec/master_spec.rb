require 'serverspec'

set :backend, :exec

describe file('/var/lib/jenkins/jenkins.war') do
  it { should be_file }
  its(:sha256sum) do
    should eq '4507a49529d15985562dfa50ca36e61949f62e5ae100652cb0d49f98ce83db79'
  end
end
