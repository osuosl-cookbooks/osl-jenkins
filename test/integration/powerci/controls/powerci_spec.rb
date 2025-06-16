control 'powerci' do
  describe command 'journalctl -u jenkins' do
    its('stdout') { should_not match(/SEVERE: Failed Loading plugin/) }
  end

  describe command('/usr/local/bin/jenkins-plugin-cli -l') do
    %w(
      ansicolor
      basic-branch-build-strategies
      build-monitor-plugin
      build-timeout
      cloud-stats
      config-file-provider
      disable-github-multibranch-status
      docker-java-api
      docker-plugin
      emailext-template
      email-ext
      embeddable-build-status
      extended-read-permission
      job-restrictions
      jquery
      label-linked-jobs
      nodelabelparameter
      pipeline-githubnotify-step
      pipeline-multibranch-defaults
      resource-disposer
    ).each do |plugin|
      its('stdout') { should match(/^#{plugin} /) }
    end
  end

  describe file('/var/lib/jenkins/config.xml') do
    %w(
      osuosl/ubuntu-ppc64le:20.04
      osuosl/ubuntu-ppc64le:22.04
      osuosl/ubuntu-ppc64le:24.04
      osuosl/debian-ppc64le:11
      osuosl/debian-ppc64le:12
      osuosl/debian-ppc64le:buster
      osuosl/debian-ppc64le:unstable
      osuosl/debian-ppc64le:sid
    ).each do |image|
      its('content') { should match(%r{<image>#{image}</image>}) }
      its('content') { should match(%r{<labelString>docker-#{image.tr('/:', '-')}</labelString>}) }
    end
    its('content') { should match(/<string>JENKINS_SLAVE_SSH_PUBKEY=ssh-rsa AAAAB3.*/) }
    its('content') { should match(/<launchTimeoutSeconds>600.*/) }
    its('content') { should match(%r{<credentialsId>powerci-docker</credentialsId>}) }
    its('content') { should match(%r{<uri>tcp://127.0.0.1:2375</uri>}) }
  end
end
