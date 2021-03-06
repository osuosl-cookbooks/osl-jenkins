# To generate this list, import the the following code into https://<ip address>/script and run it.
#
# Jenkins.instance.pluginManager.plugins.each{
#   plugin ->
#     println ("p['${plugin.getShortName()}'] = '${plugin.getVersion()}'")
# }
default['osl-jenkins']['restart_plugins'].tap do |p|
  p['structs'] = '1.23'
  p['credentials'] = '2.5'
  p['ssh-credentials'] = '1.19'
end

default['osl-jenkins']['plugins'].tap do |p|
  p['ace-editor'] = '1.1'
  p['ant'] = '1.11'
  p['antisamy-markup-formatter'] = '2.1'
  p['apache-httpcomponents-client-4-api'] = '4.5.13-1.0'
  p['authentication-tokens'] = '1.4'
  p['authorize-project'] = '1.4.0'
  p['bootstrap4-api'] = '4.6.0-3'
  p['bouncycastle-api'] = '2.20'
  p['branch-api'] = '2.6.4'
  p['build-token-root'] = '1.7'
  p['caffeine-api'] = '2.9.1-23.v51c4e2c879c8'
  p['checks-api'] = '1.7.0'
  p['cloudbees-folder'] = '6.15'
  p['command-launcher'] = '1.6'
  p['conditional-buildstep'] = '1.4.1'
  p['copyartifact'] = '1.46.1'
  p['credentials-binding'] = '1.25'
  p['cvs'] = '2.19'
  p['display-url-api'] = '2.3.5'
  p['docker-build-publish'] = '1.3.3'
  p['docker-commons'] = '1.17'
  p['docker-custom-build-environment'] = '1.7.3'
  p['docker-workflow'] = '1.26'
  p['durable-task'] = '1.37'
  p['echarts-api'] = '5.1.0-2'
  p['external-monitor-job'] = '1.7'
  p['font-awesome-api'] = '5.15.3-2'
  p['ghprb'] = '1.42.2'
  p['git'] = '4.7.2'
  p['git-client'] = '3.7.2'
  p['github'] = '1.33.1'
  p['github-api'] = '1.123'
  p['github-branch-source'] = '2.11.1'
  p['github-oauth'] = '0.33'
  p['github-organization-folder'] = '1.6'
  p['gitlab-plugin'] = '1.5.20'
  p['git-server'] = '1.9'
  p['handlebars'] = '3.0.8'
  p['icon-shim'] = '3.0.0'
  p['instant-messaging'] = '1.42'
  p['ircbot'] = '2.36'
  p['jackson2-api'] = '2.12.3'
  p['javadoc'] = '1.6'
  p['jdk-tool'] = '1.5'
  p['jjwt-api'] = '0.11.2-9.c8b45b8bb173'
  p['jquery3-api'] = '3.6.0-1'
  p['jquery-detached'] = '1.2.1'
  p['jsch'] = '0.1.55.2'
  p['junit'] = '1.50'
  p['ldap'] = '2.7'
  p['lockable-resources'] = '2.11'
  p['mailer'] = '1.34'
  p['mapdb-api'] = '1.0.9.0'
  p['matrix-auth'] = '2.6.7'
  p['matrix-project'] = '1.19'
  p['maven-plugin'] = '3.11'
  p['momentjs'] = '1.1.1'
  p['okhttp-api'] = '3.14.9'
  p['pam-auth'] = '1.6'
  p['parameterized-trigger'] = '2.40'
  p['pipeline-build-step'] = '2.13'
  p['pipeline-github-lib'] = '1.0'
  p['pipeline-graph-analysis'] = '1.11'
  p['pipeline-input-step'] = '2.12'
  p['pipeline-milestone-step'] = '1.3.2'
  p['pipeline-model-api'] = '1.8.5'
  p['pipeline-model-declarative-agent'] = '1.1.1'
  p['pipeline-model-definition'] = '1.8.5'
  p['pipeline-model-extensions'] = '1.8.5'
  p['pipeline-rest-api'] = '2.19'
  p['pipeline-stage-step'] = '2.5'
  p['pipeline-stage-tags-metadata'] = '1.8.5'
  p['pipeline-stage-view'] = '2.19'
  p['pipeline-utility-steps'] = '2.8.0'
  p['plain-credentials'] = '1.7'
  p['plugin-util-api'] = '2.2.0'
  p['popper-api'] = '1.16.1-2'
  p['resource-disposer'] = '0.15'
  p['run-condition'] = '1.5'
  p['scm-api'] = '2.6.4'
  p['script-security'] = '1.77'
  p['snakeyaml-api'] = '1.27.0'
  p['ssh-agent'] = '1.22'
  p['sshd'] = '3.0.3'
  p['ssh-slaves'] = '1.32.0'
  p['subversion'] = '2.14.2'
  p['text-finder'] = '1.16'
  p['token-macro'] = '2.15'
  p['translation'] = '1.16'
  p['trilead-api'] = '1.0.13'
  p['windows-slaves'] = '1.8'
  p['workflow-aggregator'] = '2.6'
  p['workflow-api'] = '2.44'
  p['workflow-basic-steps'] = '2.23'
  p['workflow-cps'] = '2.92'
  p['workflow-cps-global-lib'] = '2.19'
  p['workflow-durable-task-step'] = '2.39'
  p['workflow-job'] = '2.41'
  p['workflow-multibranch'] = '2.24'
  p['workflow-scm-step'] = '2.12'
  p['workflow-step-api'] = '2.23'
  p['workflow-support'] = '3.8'
  p['ws-cleanup'] = '0.39'
end
