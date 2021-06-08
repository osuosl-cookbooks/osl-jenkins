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
    emailext-template:1.2
    email-ext:2.83
    embeddable-build-status:2.0.3
    extended-read-permission:3.2
    job-restrictions:0.8
    jquery:1.12.4-1
    label-linked-jobs:6.0.1
    nodelabelparameter:1.8.1
    openstack-cloud:2.58
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
    osuosl/ubuntu-ppc64le:16.04
    osuosl/ubuntu-ppc64le:18.04
    osuosl/ubuntu-ppc64le-cuda:8.0
    osuosl/ubuntu-ppc64le-cuda:9.0
    osuosl/ubuntu-ppc64le-cuda:9.1
    osuosl/ubuntu-ppc64le-cuda:9.2
    osuosl/ubuntu-ppc64le-cuda:10.0
    osuosl/ubuntu-ppc64le-cuda:8.0-cudnn6
    osuosl/ubuntu-ppc64le-cuda:9.0-cudnn7
    osuosl/ubuntu-ppc64le-cuda:9.1-cudnn7
    osuosl/ubuntu-ppc64le-cuda:9.2-cudnn7
    osuosl/ubuntu-ppc64le-cuda:10.0-cudnn7
    osuosl/debian-ppc64le:9
    osuosl/debian-ppc64le:buster
    osuosl/debian-ppc64le:unstable
    osuosl/fedora-ppc64le:28
    osuosl/fedora-ppc64le:29
    osuosl/centos-ppc64le:7
    osuosl/centos-ppc64le-cuda:8.0
    osuosl/centos-ppc64le-cuda:9.0
    osuosl/centos-ppc64le-cuda:9.1
    osuosl/centos-ppc64le-cuda:9.2
    osuosl/centos-ppc64le-cuda:8.0-cudnn6
    osuosl/centos-ppc64le-cuda:9.0-cudnn7
    osuosl/centos-ppc64le-cuda:9.1-cudnn7
    osuosl/centos-ppc64le-cuda:9.2-cudnn7
  ).each do |image|
    its('content') { should match(%r{<image>#{image}</image>}) }
    its('content') { should match(%r{<labelString>docker-#{image.tr('/:', '-')}</labelString>}) }
    its('content') { should match(%r{<labelString>docker-#{image.tr('/:', '-')}-privileged</labelString>}) }
  end
  its('content') { should match(/<string>JENKINS_SLAVE_SSH_PUBKEY=ssh-rsa AAAAB3.*/) }
  its('content') { should match(/<launchTimeoutSeconds>600.*/) }
  its('content') { should match(%r{<credentialsId>powerci-docker</credentialsId>}) }
  its('content') { should match(%r{<uri>tcp://127.0.0.1:2375</uri>}) }
end
