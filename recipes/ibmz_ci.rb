#
# Cookbook:: osl-jenkins
# Recipe:: ibmz_ci
#
# Copyright:: 2018-2024, Oregon State University
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

node.default['osl-jenkins']['secrets_item'] = 'ibmz_ci'
secrets = credential_secrets
admin_users = secrets['admin_users']
normal_users = secrets['normal_users']
client_id = secrets['oauth']['ibmz_ci']['client_id']
client_secret = secrets['oauth']['ibmz_ci']['client_secret']
ibmz_ci = node['osl-jenkins']['ibmz_ci']

osl_jenkins_install 'ibmz-ci.osuosl.org' do
  admin_address 'nobody@osuosl.org'
  num_executors 0
  plugins %w(
    ansicolor
    build-monitor-plugin
    build-timeout
    cloud-stats
    config-file-provider
    disable-github-multibranch-status
    docker-java-api
    docker-plugin
    email-ext
    emailext-template
    embeddable-build-status
    extended-read-permission
    github-oauth
    job-restrictions
    jquery
    label-linked-jobs
    nodelabelparameter
    pipeline-githubnotify-step
    pipeline-multibranch-defaults
    resource-disposer
  )
end

osl_jenkins_service 'ibmz-ci' do
  action [:enable, :start]
end

ibmz_ci_docker = search(
  :node,
  'roles:ibmz_ci_docker',
  filter_result: {
    'ipaddress' => ['ipaddress'],
    'fqdn' => ['fqdn'],
  }
)

osl_jenkins_config 'ibmz-ci' do
  sensitive true
  variables(
    admin_users: admin_users,
    client_id: client_id,
    client_secret: client_secret,
    docker_hosts: ibmz_ci_docker,
    docker_images: ibmz_ci['docker_images'],
    docker_public_key: ibmz_ci['docker_public_key'],
    normal_users: normal_users
  )
  notifies :restart, 'osl_jenkins_service[ibmz-ci]', :delayed
end
