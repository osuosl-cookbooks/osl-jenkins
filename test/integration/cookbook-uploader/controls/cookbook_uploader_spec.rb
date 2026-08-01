control 'cookbook-uploader' do
  # The legacy per-repo freestyle jobs and the freestyle environment bumper
  # are retired: none of them may exist on a fresh install.
  describe http('https://127.0.0.1/job/cookbook-uploader-osuosl-cookbooks-test-cookbook/', ssl_verify: false) do
    its('status') { should eq 404 }
    its('headers.X-Jenkins') { should_not eq nil }
  end

  describe http('https://127.0.0.1/job/environment-bumper-osuosl-chef-repo/', ssl_verify: false) do
    its('status') { should eq 404 }
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
    # 'git' is an obsolete casc symbol for modernSCM sources.
    its('content') { should match(/gitSource:/) }
  end

  describe file('/var/lib/jenkins/casc_configs/groovy/job_github-sync.groovy') do
    its('owner') { should eq 'jenkins' }
    its('content') { should match(%r{spec\('15 \*/4 \* \* \*'\)}) }
  end

  # The legacy freestyle environment bumper's casc config is cleaned up.
  %w(
    /var/lib/jenkins/casc_configs/job_environment-bumper-osuosl-chef-repo.yml
    /var/lib/jenkins/casc_configs/groovy/job_environment-bumper-osuosl-chef-repo.groovy
  ).each do |f|
    describe file(f) do
      it { should_not exist }
    end
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
    # Only the default branch builds; MRs are validated by GitLab CI.
    its('content') { should match(/headRegexFilter/) }
    its('content') { should_not match(/gitLabOriginDiscovery/) }
  end

  # The legacy trigger scripts are retired along with the freestyle jobs.
  describe file('/var/lib/jenkins/bin/github_pr_comment_trigger.rb') do
    it { should_not exist }
  end

  describe file('/var/lib/jenkins/bin/bump_environments.rb') do
    it { should_not exist }
  end
end
