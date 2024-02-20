#
# Cookbook:: osl-jenkins
# Recipe:: powerci
#
# Copyright:: 2017-2024, Oregon State University
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

node.default['osl-jenkins']['secrets_item'] = 'powerci'
secrets = credential_secrets
admin_users = secrets['admin_users']
normal_users = secrets['normal_users']
client_id = secrets['oauth']['powerci']['client_id']
client_secret = secrets['oauth']['powerci']['client_secret']
powerci = node['osl-jenkins']['powerci']

osl_jenkins_install 'powerci.osuosl.org' do
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

osl_jenkins_service 'powerci' do
  action [:enable, :start]
end

powerci_docker = search(
  :node,
  'roles:powerci_docker',
  filter_result: {
    'ipaddress' => ['ipaddress'],
    'fqdn' => ['fqdn'],
  }
)

osl_jenkins_private_key_credentials 'powerci-docker' do
  username 'jenkins'
  private_key secrets['ssh']['powerci-docker']['private_key']
  notifies :restart, 'osl_jenkins_service[powerci]', :delayed
end

osl_jenkins_config 'powerci' do
  sensitive true
  variables(
    admin_users: admin_users,
    client_id: client_id,
    client_secret: client_secret,
    docker_hosts: powerci_docker,
    docker_images: powerci['docker_images'],
    docker_public_key: powerci['docker_public_key'],
    normal_users: normal_users
  )
  notifies :restart, 'osl_jenkins_service[powerci]', :delayed
end
