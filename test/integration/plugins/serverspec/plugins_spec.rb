require 'serverspec'

set :backend, :exec

describe file('/var/log/jenkins/jenkins.log') do
  its(:content) { should_not match(/SEVERE: Failed Loading plugin/) }
end

describe command('java -jar /tmp/kitchen/cache/jenkins-cli.jar -s http://localhost:8080/ list-plugins') do
  %w(
    ace-editor:1.1
    ant:1.2
    antisamy-markup-formatter:1.3
    authentication-tokens:1.3
    bouncycastle-api:2.16.1
    branch-api:2.0.8
    build-token-root:1.4
    cloudbees-folder:6.0.3
    conditional-buildstep:1.3.1
    credentials:2.1.13
    credentials-binding:1.13
    cvs:2.12
    display-url-api:1.1.1
    docker-commons:1.8
    docker-workflow:1.10
    durable-task:1.13
    external-monitor-job:1.4
    ghprb:1.36.1
    git:3.5.1
    git-client:2.5.0
    github:1.26.2
    github-api:1.90
    github-branch-source:2.2.3
    github-oauth:0.22.3
    github-organization-folder:1.6
    gitlab-plugin:1.4.4
    git-server:1.7
    handlebars:1.1.1
    icon-shim:2.0.3
    instant-messaging:1.35
    ircbot:2.27
    jackson2-api:2.7.3
    javadoc:1.3
    jquery-detached:1.2.1
    junit:1.20
    ldap:1.12
    mailer:1.20
    mapdb-api:1.0.6.0
    matrix-auth:1.5
    matrix-project:1.7.1
    maven-plugin:2.12.1
    momentjs:1.1.1
    pam-auth:1.2
    parameterized-trigger:2.35.1
    pipeline-build-step:2.5.1
    pipeline-github-lib:1.0
    pipeline-graph-analysis:1.3
    pipeline-input-step:2.8
    pipeline-milestone-step:1.3.1
    pipeline-model-api:1.1.2
    pipeline-model-declarative-agent:1.1.1
    pipeline-model-definition:1.1.2
    pipeline-model-extensions:1.1.2
    pipeline-rest-api:2.6
    pipeline-stage-step:2.2
    pipeline-stage-tags-metadata:1.1.2
    pipeline-stage-view:2.6
    pipeline-utility-steps:1.4.0
    plain-credentials:1.4
    run-condition:1.0
    scm-api:2.2.0
    script-security:1.39
    ssh-agent:1.15
    ssh-credentials:1.13
    ssh-slaves:1.16
    structs:1.10
    subversion:2.9
    text-finder:1.10
    token-macro:2.1
    translation:1.12
    windows-slaves:1.1
    workflow-aggregator:2.5
    workflow-api:2.20
    workflow-basic-steps:2.4
    workflow-cps:2.39
    workflow-cps-global-lib:2.7
    workflow-durable-task-step:2.10
    workflow-job:2.10
    workflow-multibranch:2.14
    workflow-scm-step:2.4
    workflow-step-api:2.12
    workflow-support:2.14
    ws-cleanup:0.28
  ).each do |plugins_version|
    plugin, version = plugins_version.split(':')
    its(:stdout) { should match(/^#{plugin}.*#{version}[\s\(]?/) }
  end
end
