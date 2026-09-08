control 'bumpzone' do
  # The freestyle jobs the pipelines replaced must not exist on a fresh install.
  %w(bumpzone checkzone).each do |job|
    describe http("https://127.0.0.1/job/#{job}/", ssl_verify: false) do
      its('status') { should eq 404 }
      its('headers.X-Jenkins') { should_not eq nil }
    end
  end

  %w(zonefiles zone-bumper update-zonefiles).each do |job|
    describe http("https://127.0.0.1/job/#{job}/", ssl_verify: false) do
      its('status') { should eq 200 }
      its('headers.X-Jenkins') { should_not eq nil }
    end
  end

  # publishChecks in the zonefiles CI pipeline puts named-checkzone's output on
  # the PR itself; without the plugin the step fails only at build time.
  describe file('/var/lib/jenkins/plugins.txt') do
    its('content') { should match(/^github-checks/) }
  end

  describe file('/var/lib/jenkins/casc_configs/groovy/job_zonefiles.groovy') do
    its('owner') { should eq 'jenkins' }
    its('content') { should match(/multibranchPipelineJob\('zonefiles'\)/) }
    its('content') { should match(%r{scriptPath\('scripts/ci/Jenkinsfile'\)}) }
    its('content') { should match(/repoOwner\('osuosl'\)/) }
    # PR builds run on the controller, which holds the push credential.
    its('content') { should_not match(/gitHubForkDiscovery/) }
  end

  describe file('/var/lib/jenkins/casc_configs/groovy/job_zone-bumper.groovy') do
    its('owner') { should eq 'jenkins' }
    its('content') { should match(/pipelineJob\('zone-bumper'\)/) }
    its('content') { should match(/genericTrigger/) }
    # Anchored: the plugin matches with find(), and only a merged PR may bump.
    its('content') { should match(/\^closed:true\$/) }
    its('content') { should match(%r{scriptPath\('scripts/ci/Jenkinsfile\.bump'\)}) }
    # The legacy build-token trigger is gone.
    its('content') { should_not match(/authenticationToken/) }
  end

  describe file('/var/lib/jenkins/casc_configs/groovy/job_update-zonefiles.groovy') do
    its('owner') { should eq 'jenkins' }
    its('content') { should match(/pipelineJob\('update-zonefiles'\)/) }
    its('content') { should match(%r{scriptPath\('scripts/ci/Jenkinsfile\.deploy'\)}) }
    its('content') { should match(/DNS_AGENT_LABEL/) }
    # Chained by an explicit downstream build from zone-bumper, not upstream().
    its('content') { should_not match(/upstream/) }
  end

  # Both casc files of each retired job are cleaned up.
  %w(bumpzone checkzone).each do |job|
    [
      "/var/lib/jenkins/casc_configs/job_#{job}.yml",
      "/var/lib/jenkins/casc_configs/groovy/job_#{job}.groovy",
    ].each do |f|
      describe file(f) do
        it { should_not exist }
      end
    end
  end

  # The ruby moved to the zonefiles repo (scripts/ci); nothing is shipped to
  # the controller any more, and the yajl shim it needed is gone with it.
  %w(
    /var/lib/jenkins/bin/bumpzone.rb
    /var/lib/jenkins/bin/checkzone.rb
    /var/lib/jenkins/lib/bumpzone.rb
    /var/lib/jenkins/lib/checkzone.rb
    /var/lib/jenkins/lib/yajl_workaround.rb
  ).each do |f|
    describe file(f) do
      it { should_not exist }
    end
  end

  describe file('/var/lib/jenkins/plugins.txt') do
    its('content') { should match(/^github-branch-source/) }
    its('content') { should match(/^generic-webhook-trigger/) }
    # slackSend is called by this recipe's deploy pipeline and by chef-repo's
    # Jenkinsfile, so slack belongs to the default set, not to one recipe.
    its('content') { should match(/^slack/) }
  end

  # named-checkzone, run by the zonefiles CI pipeline on the controller.
  describe file('/usr/sbin/named-checkzone') do
    it { should exist }
    it { should be_executable }
  end

  # The pipelines run on cinc-workstation's omnibus ruby, which already ships
  # every gem they need; nothing is installed at build time.
  describe command('/opt/cinc-workstation/embedded/bin/ruby -e "require \'octokit\'; require \'git\'"') do
    its('exit_status') { should eq 0 }
  end
end
