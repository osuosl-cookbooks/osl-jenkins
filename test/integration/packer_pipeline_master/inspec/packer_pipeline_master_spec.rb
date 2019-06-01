# describe command('curl -k https://127.0.0.1/job/packer_pipeline/ -o /dev/null -v 2>&1') do
#   its(:stdout) { should match(/X-Jenkins-Session:/) }
#   its(:exit_status) { should eq 0 }
# end

describe http('https://127.0.0.1/job/packer_pipeline/', enable_remote_worker: true, ssl_verify: false) do
  its('body') { should match(/X-Jenkins-Session:/) }
end

describe file('/var/lib/jenkins/lib/packer_pipeline.rb') do
  its('mode') { should cmp 0440 }
  its('owner') { should eq 'jenkins' }
  its('group') { should eq 'jenkins' }
end

describe file('/var/lib/jenkins/bin/packer_pipeline.rb') do
  its('mode') { should cmp 0550 }
  its('owner') { should eq 'jenkins' }
  its('group') { should eq 'jenkins' }
end

describe command('/opt/chef/embedded/bin/gem list --local') do
  %w(git octokit faraday-http-cache).each do |g|
    its('stdout') { should match(/^#{g}/) }
  end
end
