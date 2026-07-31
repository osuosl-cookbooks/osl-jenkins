control 'cookbook-uploader' do
  # test-cookbook has migrated to the label-driven pipeline (Jenkinsfile in
  # the repo), so its legacy freestyle job is deleted instead of created and
  # must not exist on a fresh install.
  describe http('https://127.0.0.1/job/cookbook-uploader-osuosl-cookbooks-test-cookbook/', ssl_verify: false) do
    its('status') { should eq 404 }
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

  describe http('https://127.0.0.1/job/osuosl-cookbooks/', ssl_verify: false) do
    its('status') { should eq 200 }
    its('headers.X-Jenkins') { should_not eq nil }
  end

  describe http('https://127.0.0.1/job/cookbook-uploader/', ssl_verify: false) do
    its('status') { should eq 200 }
    its('headers.X-Jenkins') { should_not eq nil }
  end

  describe http('https://127.0.0.1/job/environment-bumper/', ssl_verify: false) do
    its('status') { should eq 200 }
    its('headers.X-Jenkins') { should_not eq nil }
  end

  describe http('https://127.0.0.1/job/github-sync/', ssl_verify: false) do
    its('status') { should eq 200 }
    its('headers.X-Jenkins') { should_not eq nil }
  end

  describe http('https://127.0.0.1/job/chef-repo/', ssl_verify: false) do
    its('status') { should eq 200 }
    its('headers.X-Jenkins') { should_not eq nil }
  end

  describe http('https://127.0.0.1/job/data-bags/', ssl_verify: false) do
    its('status') { should eq 200 }
    its('headers.X-Jenkins') { should_not eq nil }
  end

  describe file('/var/lib/jenkins/casc_configs/groovy/job_cookbook-uploader.groovy') do
    its('owner') { should eq 'jenkins' }
    its('content') { should match(/pipelineJob\('cookbook-uploader'\)/) }
    its('content') { should match(/genericTrigger/) }
    its('content') { should match(%r{\^labeled:bump/\(major\|minor\|patch\|skip\)\$}) }
    # The comment path must stay off while the legacy freestyle jobs exist.
    its('content') { should_not match(/gh_comment/) }
  end

  describe file('/var/lib/jenkins/casc_configs/shared_library.yml') do
    its('owner') { should eq 'jenkins' }
    its('content') { should match(/name: osl-pipelines/) }
    its('content') { should match(%r{remote: https://github.com/osuosl/cookbook-pipelines.git}) }
  end

  describe file('/var/lib/jenkins/casc_configs/groovy/job_osuosl-cookbooks.groovy') do
    its('owner') { should eq 'jenkins' }
    its('content') { should match(/organizationFolder\('osuosl-cookbooks'\)/) }
    its('content') { should match(/gitHubTrustPermissions/) }
  end

  describe file('/var/lib/jenkins/plugins.txt') do
    its('content') { should match(/^github-branch-source/) }
    its('content') { should match(/^generic-webhook-trigger/) }
    its('content') { should match(/^pipeline-utility-steps/) }
    its('content') { should match(/^gitlab-branch-source/) }
  end

  describe file('/var/lib/jenkins/casc_configs/gitlab_server.yml') do
    its('owner') { should eq 'jenkins' }
    its('content') { should match(/name: git.osuosl.org/) }
    its('content') { should match(%r{serverUrl: https://git.osuosl.org}) }
    its('content') { should match(/manageWebHooks: true/) }
  end

  describe file('/var/lib/jenkins/casc_configs/groovy/job_data-bags.groovy') do
    its('owner') { should eq 'jenkins' }
    its('content') { should match(/multibranchPipelineJob\('data-bags'\)/) }
    its('content') { should match(/serverName\('git.osuosl.org'\)/) }
    its('content') { should match(/gitLabSshCheckout/) }
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
    its('stdout') { should_not match(/^faraday-http-cache \(2\.[6-9]|^faraday-http-cache \([3-9]/) }
    its('stdout') { should_not match(/^git \([4-9]\./) }
    its('stdout') { should_not match(/^octokit \(1[0-9]/) }
  end

  describe command("/opt/cinc/embedded/bin/ruby -e \"require 'octokit'\"") do
    its('exit_status') { should eq 0 }
  end
end
