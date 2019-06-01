describe file('/var/log/jenkins/jenkins.log') do
  its('content') { should_not match(/SEVERE: Failed Loading plugin/) }
end

describe command('java -jar /tmp/kitchen/cache/jenkins-cli.jar -s http://localhost:8080/ list-plugins') do
  %w(
    ace-editor:1.1
    ansicolor:0.5.2
    apache-httpcomponents-client-4-api:4.5.5-3.0
    authentication-tokens:1.3
    bouncycastle-api:2.16.3
    branch-api:2.0.8
    build-monitor-plugin:1.11\+build.201701152243
    build-timeout:1.19
    build-token-root:1.4
    cloudbees-folder:6.0.3
    cloud-stats:0.11
    command-launcher:1.2
    config-file-provider:3.6
    display-url-api:2.2.0
    docker-java-api:3.0.14
    docker-plugin:1.1.3
    durable-task:1.17
    email-ext:2.66
    emailext-template:1.1
    embeddable-build-status:1.9
    git:3.9.3
    git-client:2.7.1
    github:1.29.2
    github-api:1.90
    github-branch-source:2.3.6
    github-oauth:0.31
    git-server:1.7
    handlebars:1.1.1
    icon-shim:2.0.3
    job-restrictions:0.6
    jquery:1.12.4-0
    jquery-detached:1.2.1
    jsch:0.1.54.2
    junit:1.26.1
    label-linked-jobs:5.1.2
    mailer:1.21
    matrix-auth:1.5
    matrix-project:1.14
    momentjs:1.1.1
    nodelabelparameter:1.7.2
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
    scm-api:2.2.7
    script-security:1.56
    ssh-credentials:1.14
    ssh-slaves:1.28.1
    structs:1.17
    token-macro:2.7
    workflow-aggregator:2.5
    workflow-api:2.30
    workflow-basic-steps:2.6
    workflow-cps:2.65
    workflow-cps-global-lib:2.9
    workflow-durable-task-step:2.18
    workflow-job:2.26
    workflow-multibranch:2.16
    workflow-scm-step:2.6
    workflow-step-api:2.19
    workflow-support:3.2
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
