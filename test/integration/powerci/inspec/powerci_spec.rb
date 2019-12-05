describe file('/var/log/jenkins/jenkins.log') do
  its('content') { should_not match(/SEVERE: Failed Loading plugin/) }
end

describe command('java -jar /tmp/kitchen/cache/jenkins-cli.jar -s http://localhost:8080/ list-plugins') do
  %w(
    ace-editor:1.1
    ansicolor:0.5.2
    apache-httpcomponents-client-4-api:4.5.10-2.0
    authentication-tokens:1.3
    authorize-project:1.3.0
    bouncycastle-api:2.16.3
    branch-api:2.0.8
    build-monitor-plugin:1.11\+build.201701152243
    build-timeout:1.19
    build-token-root:1.4
    cloudbees-folder:6.9
    cloud-stats:0.14
    command-launcher:1.2
    config-file-provider:3.6
    copy-to-slave:1.4.4
    credentials:2.3.0
    display-url-api:2.2.0
    docker-java-api:3.0.14
    docker-plugin:1.1.9
    durable-task:1.17
    email-ext:2.66
    emailext-template:1.1
    embeddable-build-status:2.0.3
    git:3.9.3
    git-client:3.0.0
    github:1.29.2
    github-api:1.90
    github-branch-source:2.3.6
    github-oauth:0.33
    gitlab-plugin:1.5.13
    git-server:1.7
    handlebars:1.1.1
    icon-shim:2.0.3
    instant-messaging:1.38
    ircbot:2.31
    job-restrictions:0.6
    jquery:1.12.4-0
    jquery-detached:1.2.1
    jsch:0.1.55.1
    junit:1.26.1
    label-linked-jobs:5.1.2
    mailer:1.21
    matrix-auth:2.5
    matrix-project:1.14
    maven-plugin:3.4
    momentjs:1.1.1
    nodelabelparameter:1.7.2
    openstack-cloud:2.37
    pam-auth:1.6
    pipeline-build-step:2.5.1
    pipeline-graph-analysis:1.3
    pipeline-input-step:2.8
    pipeline-milestone-step:1.3.1
    pipeline-model-declarative-agent:1.1.1
    pipeline-multibranch-defaults:1.1
    pipeline-rest-api:2.6
    pipeline-stage-step:2.3
    pipeline-stage-view:2.6
    plain-credentials:1.4
    resource-disposer:0.12
    scm-api:2.6.3
    script-security:1.68
    ssh-credentials:1.18
    ssh-slaves:1.28.1
    structs:1.20
    token-macro:2.10
    trilead-api:1.0.5
    workflow-aggregator:2.5
    workflow-api:2.33
    workflow-basic-steps:2.6
    workflow-cps:2.71
    workflow-cps-global-lib:2.15
    workflow-durable-task-step:2.18
    workflow-job:2.26
    workflow-multibranch:2.16
    workflow-scm-step:2.7
    workflow-step-api:2.20
    workflow-support:3.3
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
