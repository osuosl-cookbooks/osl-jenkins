require 'spec_helper'

set :backend, :exec

describe 'bindzone' do
  it_behaves_like 'jenkins_server'
end

describe command('curl -k https://127.0.0.1/job/bumpzone/ -o /dev/null -v 2>&1') do
  its(:stdout) { should match(/X-Jenkins-Session:/) }
  its(:exit_status) { should eq 0 }
end

describe file('/var/lib/jenkins/lib/bumpzone.rb') do
  it { should be_mode 440 }
  it { should be_owned_by 'jenkins' }
  it { should be_grouped_into 'jenkins' }
end

describe file('/var/lib/jenkins/bin/bumpzone.rb') do
  it { should be_mode 550 }
  it { should be_owned_by 'jenkins' }
  it { should be_grouped_into 'jenkins' }
end

describe command('/opt/chef/embedded/bin/gem list --local') do
  %w(git octokit).each do |g|
    its(:stdout) { should match(/^#{g}/) }
  end
end
