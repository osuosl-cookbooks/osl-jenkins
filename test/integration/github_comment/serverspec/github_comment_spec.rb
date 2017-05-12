require 'serverspec'
require 'spec_helper'

set :backend, :exec

describe file('/var/lib/jenkins/plugins/ghprb.jpi') do
  it { should be_file }
end

describe file('/var/lib/jenkins/bin/github_comment.rb') do
  it { should be_file }
  it { should be_mode 550 }
  it { should be_owned_by 'jenkins' }
  it { should be_grouped_into 'jenkins' }
end

describe file('/var/lib/jenkins/lib/github_comment.rb') do
  it { should be_file }
  it { should be_mode 440 }
  it { should be_owned_by 'jenkins' }
  it { should be_grouped_into 'jenkins' }
end

describe 'github_comment' do
  it_behaves_like 'jenkins_server'
end

describe command('curl -k https://127.0.0.1/job/github_comment/ -o /dev/null -v 2>&1') do
  its(:stdout) { should match(/X-Jenkins-Session:/) }
  its(:exit_status) { should eq 0 }
end
