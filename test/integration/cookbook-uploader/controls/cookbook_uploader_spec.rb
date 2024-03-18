control 'cookbook-uploader' do
  describe http('https://127.0.0.1/job/cookbook-uploader-osuosl-cookbooks-test-cookbook/', ssl_verify: false) do
    its('status') { should eq 200 }
    its('headers.X-Jenkins') { should_not eq nil }
  end

  describe http('https://127.0.0.1/job/cookbook-uploader-osuosl-cookbooks-archived-cookbook/', ssl_verify: false) do
    its('status') { should eq 404 }
    its('headers.X-Jenkins') { should_not eq nil }
  end

  describe http('https://127.0.0.1/job/environment-bumper-osuosl-chef-repo/', ssl_verify: false) do
    its('status') { should eq 200 }
    its('headers.X-Jenkins') { should_not eq nil }
  end

  describe file('/var/lib/jenkins/bin/github_pr_comment_trigger.rb') do
    its('mode') { should cmp 0550 }
    its('owner') { should eq 'jenkins' }
    its('group') { should eq 'jenkins' }
  end

  describe file('/var/lib/jenkins/bin/bump_environments.rb') do
    its('mode') { should cmp 0550 }
    its('owner') { should eq 'jenkins' }
    its('group') { should eq 'jenkins' }
  end

  describe command('/opt/cinc/embedded/bin/gem list --local') do
    %w(
      faraday-http-cache
      git
      octokit
    ).each do |g|
      its('stdout') { should match(/^#{g}/) }
    end
  end
end
