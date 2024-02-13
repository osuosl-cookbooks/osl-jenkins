control 'ibmz-ci' do
  describe command 'journalctl -u jenkins' do
    its('stdout') { should_not match(/SEVERE: Failed Loading plugin/) }
  end

  describe command '/usr/local/bin/jenkins-plugin-cli -l' do
    %w(
      ansicolor
      build-monitor-plugin
      build-timeout
      cloud-stats
      config-file-provider
      disable-github-multibranch-status
      docker-java-api
      docker-plugin
      email-ext
      emailext-template
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
      osuosl/ubuntu-s390x:16.04
      osuosl/ubuntu-s390x:18.04
      osuosl/debian-s390x:9
      osuosl/debian-s390x:buster
      osuosl/debian-s390x:unstable
      osuosl/fedora-s390x:28
      osuosl/fedora-s390x:29
    ).each do |image|
      its('content') { should match(%r{<image>#{image}</image>}) }
      its('content') { should match(%r{<labelString>docker-#{image.tr('/:', '-')}</labelString>}) }
    end
    its('content') { should match(/<string>JENKINS_SLAVE_SSH_PUBKEY=ssh-rsa AAAAB3.*/) }
    its('content') { should match(%r{<credentialsId>ibmz_ci-docker</credentialsId>}) }
    its('content') { should match(%r{<uri>tcp://127.0.0.1:2376</uri>}) }
    its('content') { should match(%r{<credentialsId>ibmz_ci_docker-server</credentialsId>}) }
  end
end
