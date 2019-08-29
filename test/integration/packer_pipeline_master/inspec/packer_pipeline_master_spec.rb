describe http('https://127.0.0.1/job/packer_pipeline/', enable_remote_worker: true, ssl_verify: false) do
  its('status') { should eq 200 }
  its('headers.X-Jenkins') { should_not eq nil }
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
