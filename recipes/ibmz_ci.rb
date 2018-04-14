#
# Cookbook:: osl-jenkins
# Recipe:: ibmz_ci
#
# Copyright:: 2018, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class ::Chef::Recipe
  include OSLDocker::Helper
  include OSLGithubOauth::Helper
end

node.default['osl-jenkins']['secrets_item'] = 'ibmz_ci'
secrets = credential_secrets
admin_users = secrets['admin_users']
normal_users = secrets['normal_users']
client_id = secrets['oauth']['ibmz_ci']['client_id']
client_secret = secrets['oauth']['ibmz_ci']['client_secret']
ibmz_ci = node['osl-jenkins']['ibmz_ci']
docker_cert = data_bag_item(
  node['osl-docker']['data_bag'],
  "client-#{node['fqdn'].tr('.', '-')}"
)

ruby_block 'Set jenkins username/password if needed' do
  block do
    if ::File.exist?('/var/lib/jenkins/config.xml') &&
       ::File.foreach('/var/lib/jenkins/config.xml').grep(/GithubSecurityRealm/).any?
      node.run_state[:jenkins_username] = secrets['git']['ibmz_ci']['user'] # ~FC001
      node.run_state[:jenkins_password] = secrets['git']['ibmz_ci']['token'] # ~FC001
    end
  end
end

node.default['osl-jenkins']['plugins'] = %w(
  ace-editor:1.1
  apache-httpcomponents-client-4-api:4.5.3-2.1
  authentication-tokens:1.3
  bouncycastle-api:2.16.2
  branch-api:2.0.8
  build-monitor-plugin:1.11+build.201701152243
  build-token-root:1.4
  cloudbees-folder:6.0.3
  cloud-stats:0.11
  command-launcher:1.2
  config-file-provider:2.16.2
  credentials-binding:1.15
  display-url-api:2.2.0
  docker-build-publish:1.3.2
  docker-commons:1.11
  docker-java-api:3.0.14
  docker-plugin:1.1.3
  docker-workflow:1.15.1
  durable-task:1.17
  email-ext:2.57.2
  emailext-template:1.0
  embeddable-build-status:1.9
  git:3.8.0
  git-client:2.7.1
  github:1.29.0
  github-api:1.90
  github-branch-source:2.2.3
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
  resource-disposer:0.6
  scm-api:2.2.6
  script-security:1.39
  ssh-slaves:1.26
  token-macro:2.4
  workflow-aggregator:2.5
  workflow-api:2.25
  workflow-basic-steps:2.4
  workflow-cps:2.39
  workflow-cps-global-lib:2.8
  workflow-durable-task-step:2.18
  workflow-job:2.10
  workflow-multibranch:2.14
  workflow-scm-step:2.4
  workflow-step-api:2.14
  workflow-support:2.18
)

include_recipe 'osl-jenkins::master'

if Chef::Config[:solo] && !defined?(ChefSpec)
  Chef::Log.warn('This recipe uses search which Chef Solo does not support') if Chef::Config[:solo]
else
  docker_hosts = "\n"
  ibmz_ci_docker = search(
    :node,
    'roles:ibmz_ci_docker',
    filter_result: {
      'ipaddress' => ['ipaddress'],
      'fqdn' => ['fqdn']
    }
  )
end

unless ibmz_ci_docker.nil?
  ibmz_ci_docker.each do |host|
    docker_hosts += add_docker_host(host['fqdn'], host['ipaddress'], 'ibmz_ci_docker-server')
  end
end

docker_images = "\n"
ibmz_ci['docker_images'].each do |image|
  docker_images +=
    add_docker_image(
      image,
      ibmz_ci['docker_public_key'],
      ibmz_ci['docker']['memory_limit'],
      ibmz_ci['docker']['memory_swap'],
      ibmz_ci['docker']['cpu_shared']
    )
end

docker_cloud =
  add_docker_cloud(
    docker_images,
    docker_hosts,
    docker_cert['key'],
    docker_cert['cert'],
    docker_cert['chain'],
    'ibmz_ci-docker',
    'ibmz_ci_docker-server'
  )

github_oauth =
  add_github_oauth(
    client_id,
    client_secret,
    admin_users,
    normal_users
  )

jenkins_script 'Add Docker Cloud' do
  command docker_cloud
end

jenkins_script 'Add GitHub OAuth config' do
  command github_oauth
end

ruby_block 'Set jenkins username/password if needed' do
  block do
    if ::File.exist?('/var/lib/jenkins/config.xml') &&
       ::File.foreach('/var/lib/jenkins/config.xml').grep(/GithubSecurityRealm/).any?
      node.run_state[:jenkins_username] = secrets['git']['ibmz_ci']['user'] # ~FC001
      node.run_state[:jenkins_password] = secrets['git']['ibmz_ci']['token'] # ~FC001
    end
  end
end
