require 'spec_helper'

set :backend, :exec

describe 'powerci' do
  it_behaves_like 'jenkins_server'
end

describe file('/var/log/jenkins/jenkins.log') do
  its(:content) { should_not match(/SEVERE: Failed Loading plugin/) }
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
    cloud-stats:0.14
    command-launcher:1.2
    config-file-provider:2.16.2
    copy-to-slave:1.4.4
    credentials:2.1.17
    credentials-binding:1.15
    display-url-api:2.2.0
    docker-build-publish:1.3.2
    docker-commons:1.11
    docker-java-api:3.0.14
    docker-plugin:1.1.3
    docker-workflow:1.15.1
    durable-task:1.17
    email-ext:2.62
    emailext-template:1.0
    embeddable-build-status:1.9
    git:3.9.1
    git-client:2.7.1
    github:1.29.2
    github-api:1.90
    github-branch-source:2.3.6
    github-oauth:0.27
    git-server:1.7
    handlebars:1.1.1
    icon-shim:2.0.3
    jackson2-api:2.7.3
    job-restrictions:0.6
    jquery-detached:1.2.1
    jsch:0.1.54.2
    junit:1.24
    mailer:1.21
    matrix-auth:1.5
    matrix-project:1.13
    momentjs:1.1.1
    openstack-cloud:2.37
    pipeline-build-step:2.5.1
    pipeline-graph-analysis:1.3
    pipeline-input-step:2.8
    pipeline-milestone-step:1.3.1
    pipeline-model-api:1.1.3
    pipeline-model-declarative-agent:1.1.1
    pipeline-model-definition:1.1.3
    pipeline-model-extensions:1.1.3
    pipeline-multibranch-defaults:1.1
    pipeline-rest-api:2.6
    pipeline-stage-step:2.2
    pipeline-stage-tags-metadata:1.1.3
    pipeline-stage-view:2.6
    plain-credentials:1.4
    resource-disposer:0.12
    scm-api:2.2.6
    script-security:1.39
    sge-cloud-plugin:1.17
    ssh-credentials:1.14
    ssh-slaves:1.26
    structs:1.14
    token-macro:2.4
    workflow-aggregator:2.5
    workflow-api:2.25
    workflow-basic-steps:2.4
    workflow-cps:2.39
    workflow-cps-global-lib:2.8
    workflow-durable-task-step:2.18
    workflow-job:2.11
    workflow-multibranch:2.14
    workflow-scm-step:2.4
    workflow-step-api:2.16
    workflow-support:2.18
  ).each do |plugins_version|
    plugin, version = plugins_version.split(':')
    its(:stdout) { should match(/^#{plugin}.*#{version}[\s\(]?/) }
  end
end

describe file('/var/lib/jenkins/config.xml') do
  %w(
    osuosl/ubuntu-ppc64le:16.04
    osuosl/ubuntu-ppc64le:18.04
    osuosl/ubuntu-ppc64le-cuda:8.0
    osuosl/ubuntu-ppc64le-cuda:8.0-cudnn6
    osuosl/ubuntu-ppc64le-cuda:9.0-cudnn7
    osuosl/ubuntu-ppc64le-cuda:9.1-cudnn7
    osuosl/debian-ppc64le:9
    osuosl/fedora-ppc64le:26
    osuosl/centos-ppc64le:7
    osuosl/centos-ppc64le-cuda:8.0
    osuosl/centos-ppc64le-cuda:8.0-cudnn6
  ).each do |image|
    its(:content) { should match(%r{<image>#{image}</image>}) }
  end
  its(:content) { should match(/<string>JENKINS_SLAVE_SSH_PUBKEY=ssh-rsa AAAAB3.*/) }
  its(:content) { should match(/<launchTimeoutSeconds>600.*/) }
  its(:content) { should match(%r{<credentialsId>powerci-docker</credentialsId>}) }
  its(:content) { should match(%r{<uri>tcp://127.0.0.1:2375</uri>}) }
  its(:content) do
    should match(%r{
    <org.jenkinsci.plugins.sge.BatchCloud plugin="sge-cloud-plugin@1.17">
      <name>CGRB-ubuntu</name>
      <cloudName>CGRB-ubuntu</cloudName>
      <queueType>docker_gpu</queueType>
      <label>docker-gpu</label>
      <maximumIdleMinutes>1440</maximumIdleMinutes>
      <hostname>sge.example.org</hostname>
      <port>22</port>
      <username>username</username>
      <password>\{.*\}</password>
    <\/org.jenkinsci.plugins.sge.BatchCloud>})
  end
  its(:content) do
    should match(%r{
    <org.jenkinsci.plugins.sge.BatchCloud plugin="sge-cloud-plugin@1.17">
      <name>CGRB-ubuntu-cuda91</name>
      <cloudName>CGRB-ubuntu-cuda91</cloudName>
      <queueType>docker_gpu@openpower3</queueType>
      <label>docker-gpu-cuda91</label>
      <maximumIdleMinutes>1440</maximumIdleMinutes>
      <hostname>sge.example.org</hostname>
      <port>22</port>
      <username>username</username>
      <password>\{.*\}</password>
    <\/org.jenkinsci.plugins.sge.BatchCloud>})
  end
  its(:content) do
    should match(%r{
    <org.jenkinsci.plugins.sge.BatchCloud plugin="sge-cloud-plugin@1.17">
      <name>CGRB-ubuntu-cuda92</name>
      <cloudName>CGRB-ubuntu-cuda92</cloudName>
      <queueType>docker_gpu@openpower2</queueType>
      <label>docker-gpu-cuda92</label>
      <maximumIdleMinutes>1440</maximumIdleMinutes>
      <hostname>sge.example.org</hostname>
      <port>22</port>
      <username>username</username>
      <password>\{.*\}</password>
    <\/org.jenkinsci.plugins.sge.BatchCloud>})
  end
end
