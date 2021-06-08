describe file('/var/log/jenkins/jenkins.log') do
  its('content') { should_not match(/SEVERE: Failed Loading plugin/) }
end

describe command('java -jar /tmp/kitchen/cache/jenkins-cli.jar -s http://localhost:8080/ list-plugins') do
  %w(
    ansicolor:1.0.0
    build-monitor-plugin:1.12\+build.201809061734
    build-timeout:1.20
    cloud-stats:0.27
    config-file-provider:3.8.0
    disable-github-multibranch-status:1.2
    docker-java-api:3.1.5.2
    docker-plugin:1.2.2
    email-ext:2.83
    emailext-template:1.2
    embeddable-build-status:2.0.3
    extended-read-permission:3.2
    job-restrictions:0.8
    jquery:1.12.4-1
    label-linked-jobs:6.0.1
    nodelabelparameter:1.8.1
    pipeline-githubnotify-step:1.0.5
    pipeline-multibranch-defaults:2.1
    resource-disposer:0.15
  ).each do |plugins_version|
    plugin, version = plugins_version.split(':')
    its('stdout') { should match(/^#{plugin}.*#{version}[\s\(]?/) }
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
    its('content') { should match(%r{<labelString>docker-#{image.tr('/:', '-')}-privileged</labelString>}) }
  end
  its('content') { should match(/<string>JENKINS_SLAVE_SSH_PUBKEY=ssh-rsa AAAAB3.*/) }
  its('content') { should match(%r{<credentialsId>ibmz_ci-docker</credentialsId>}) }
  its('content') { should match(%r{<uri>tcp://127.0.0.1:2376</uri>}) }
  its('content') { should match(%r{<credentialsId>ibmz_ci_docker-server</credentialsId>}) }
end
