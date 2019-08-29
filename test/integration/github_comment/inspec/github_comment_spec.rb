describe file('/var/lib/jenkins/plugins/ghprb.jpi') do
  it { should be_file }
end

describe file('/var/lib/jenkins/bin/github_comment.rb') do
  it { should be_file }
  its('mode') { should cmp 0550 }
  its('owner') { should eq 'jenkins' }
  its('group') { should eq 'jenkins' }
end

describe file('/var/lib/jenkins/lib/github_comment.rb') do
  it { should be_file }
  its('mode') { should cmp 0440 }
  its('owner') { should eq 'jenkins' }
  its('group') { should eq 'jenkins' }
end

describe http('https://127.0.0.1/job/github_comment/', enable_remote_worker: true, ssl_verify: false) do
  its('status') { should eq 200 }
  its('headers.X-Jenkins') { should_not eq nil }
end
