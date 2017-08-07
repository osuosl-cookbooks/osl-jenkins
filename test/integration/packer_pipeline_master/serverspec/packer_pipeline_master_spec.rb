require 'spec_helper'

set :backend, :exec

describe 'packer_pipeline_master' do
  it_behaves_like 'jenkins_server'
end

describe command('curl -k https://127.0.0.1/job/packer_pipeline/ -o /dev/null -v 2>&1') do
  its(:stdout) { should match(/X-Jenkins-Session:/) }
  its(:exit_status) { should eq 0 }
end

describe file('/var/lib/jenkins/lib/packer_pipeline.rb') do
  it { should be_mode 440 }
  it { should be_owned_by 'jenkins' }
  it { should be_grouped_into 'jenkins' }
end

describe file('/var/lib/jenkins/bin/packer_pipeline.rb') do
  it { should be_mode 550 }
  it { should be_owned_by 'jenkins' }
  it { should be_grouped_into 'jenkins' }
end

describe command('/opt/chef/embedded/bin/gem list --local') do
  %w(git octokit faraday-http-cache).each do |g|
    its(:stdout) { should match(/^#{g}/) }
  end
end
