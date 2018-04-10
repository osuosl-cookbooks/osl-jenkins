#
# Cookbook Name:: osl-jenkins
# Recipe:: powerci
#
# Copyright 2017, Oregon State University
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
#

class ::Chef::Recipe
  include OSLDocker::Helper
  include OSLOpenStack::Helper
  include OSLSGE::Helper
  include OSLGithubOauth::Helper
end

node.default['osl-jenkins']['secrets_item'] = 'powerci'
secrets = credential_secrets
admin_users = secrets['admin_users']
normal_users = secrets['normal_users']
client_id = secrets['oauth']['powerci']['client_id']
client_secret = secrets['oauth']['powerci']['client_secret']
sge = secrets['sge']
powerci = node['osl-jenkins']['powerci']

ruby_block 'Set jenkins username/password if needed' do
  block do
    if ::File.exist?('/var/lib/jenkins/config.xml') &&
       ::File.foreach('/var/lib/jenkins/config.xml').grep(/GithubSecurityRealm/).any?
      node.run_state[:jenkins_username] = secrets['git']['powerci']['user'] # ~FC001
      node.run_state[:jenkins_password] = secrets['git']['powerci']['token'] # ~FC001
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
  display-url-api:2.0
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
  github:1.27.0
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
  mailer:1.20
  matrix-auth:1.5
  matrix-project:1.10
  momentjs:1.1.1
  openstack-cloud:2.22
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

# Install directly from a URL since this doesn't appear to be included in the package data
jenkins_plugin 'copy-to-slave' do
  source 'http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/copy-to-slave/1.4.4/copy-to-slave-1.4.4.hpi'
  version '1.4.4'
  install_deps false
  notifies :execute, 'jenkins_command[safe-restart]', :immediately
end

jenkins_plugin 'sge-cloud-plugin' do
  source 'http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/sge-cloud-plugin/1.17/sge-cloud-plugin-1.17.hpi'
  version '1.17'
  install_deps false
  notifies :execute, 'jenkins_command[safe-restart]', :immediately
end

if Chef::Config[:solo] && !defined?(ChefSpec)
  Chef::Log.warn('This recipe uses search which Chef Solo does not support') if Chef::Config[:solo]
else
  docker_hosts = "\n"
  powerci_docker = search(
    :node,
    'roles:powerci_docker',
    filter_result: {
      'ipaddress' => ['ipaddress'],
      'fqdn' => ['fqdn']
    }
  )
end

unless powerci_docker.nil?
  powerci_docker.each do |host|
    docker_hosts += add_docker_host(host['fqdn'], host['ipaddress'], nil)
  end
end

docker_images = "\n"
powerci['docker_images'].each do |image|
  docker_images +=
    add_docker_image(
      image,
      powerci['docker_public_key'],
      powerci['docker']['memory_limit'],
      powerci['docker']['memory_swap'],
      powerci['docker']['cpu_shared']
    )
end

docker_cloud =
  add_docker_cloud(
    docker_images,
    docker_hosts,
    nil, nil, nil,
    'powerci-docker',
    nil
  )

openstack_cloud = add_openstack_cloud
sge_cloud =
  add_sge_cloud(
    'CGRB-ubuntu',
    'ubuntu',
    'docker-gpu',
    sge['hostname'],
    sge['username'],
    sge['password'],
    sge['port']
  )

github_oauth =
  add_github_oauth(
    client_id,
    client_secret,
    admin_users,
    normal_users
  )

jenkins_script 'Add Docker Cloud' do # ~FC005
  command docker_cloud
end

jenkins_script 'Add OpenStack Cloud' do
  command openstack_cloud
end

jenkins_script 'Add SGE Cloud' do
  command sge_cloud
end

jenkins_script 'Add GitHub OAuth config' do
  command github_oauth
end

ruby_block 'Set jenkins username/password if needed' do
  block do
    if ::File.exist?('/var/lib/jenkins/config.xml') &&
       ::File.foreach('/var/lib/jenkins/config.xml').grep(/GithubSecurityRealm/).any?
      node.run_state[:jenkins_username] = secrets['git']['powerci']['user'] # ~FC001
      node.run_state[:jenkins_password] = secrets['git']['powerci']['token'] # ~FC001
    end
  end
end
