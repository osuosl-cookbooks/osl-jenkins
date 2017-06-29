require 'spec_helper'

set :backend, :exec

describe service('haproxy') do
  it { should be_running }
end

describe 'powerci' do
  it_behaves_like 'jenkins_server'
end

describe file('/var/log/jenkins/jenkins.log') do
  its(:content) { should_not match(/SEVERE: Failed Loading plugin/) }
end

describe command('java -jar /tmp/kitchen/cache/jenkins-cli.jar -s http://localhost:8080/ list-plugins') do
  %w(
    docker-commons:1.6
    ssh-slaves:1.17
    resource-disposer:0.6
    pipeline-model-extensions:1.1.3
    github:1.27.0
    structs:1.6
    emailext-template:1.0
    git:3.3.0
    pipeline-stage-tags-metadata:1.1.3
    workflow-scm-step:2.4
    github-api:1.85
    workflow-cps-global-lib:2.8
    openstack-cloud:2.22
    cloudbees-folder:6.0.3
    junit:1.20
    bouncycastle-api:2.16.1
    display-url-api:2.0
    matrix-project:1.10
    config-file-provider:2.15.7
    handlebars:1.1.1
    credentials-binding:1.11
    workflow-cps:2.30
    workflow-job:2.10
    email-ext:2.57.2
    pipeline-milestone-step:1.3.1
    icon-shim:2.0.3
    authentication-tokens:1.3
    pipeline-rest-api:2.6
    docker-build-publish:1.3.2
    git-client:2.4.5
    jquery-detached:1.2.1
    pipeline-input-step:2.7
    momentjs:1.1.1
    ssh-credentials:1.13
    workflow-support:2.14
    yet-another-docker-plugin:0.1.0-rc37
    pipeline-build-step:2.5
    matrix-auth:1.5
    workflow-multibranch:2.14
    branch-api:2.0.8
    embeddable-build-status:1.9
    token-macro:2.1
    workflow-step-api:2.9
    build-monitor-plugin:1.11\+build.201701152243
    pipeline-multibranch-defaults:1.1
    pipeline-model-declarative-agent:1.1.1
    ace-editor:1.1
    docker-workflow:1.10
    workflow-durable-task-step:2.11
    workflow-api:2.13
    github-branch-source:2.0.5
    docker-plugin:0.16.2
    pipeline-model-definition:1.1.3
    workflow-basic-steps:2.4
    mailer:1.20
    credentials:2.1.13
    pipeline-model-api:1.1.3
    pipeline-stage-step:2.2
    durable-task:1.13
    scm-api:2.1.1
    cloud-stats:0.11
    plain-credentials:1.4
    github-oauth:0.27
    pipeline-graph-analysis:1.3
    script-security:1.27
    workflow-aggregator:2.5
    job-restrictions:0.6
    pipeline-stage-view:2.6
    git-server:1.7
  ).each do |plugins_version|
    plugin, version = plugins_version.split(':')
    its(:stdout) { should match(/^#{plugin}.*#{version}[\s\(]?/) }
  end
end
