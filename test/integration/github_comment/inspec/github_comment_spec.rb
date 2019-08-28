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

describe command('curl -k https://127.0.0.1/job/github_comment/ -o /dev/null -v 2>&1 | iconv -f US-ASCII -t UTF-8') do
  its('stdout') { should match(/X-Jenkins-Session:/) }
  its('exit_status') { should eq 0 }
end
