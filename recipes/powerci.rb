#
# Cookbook:: osl-jenkins
# Recipe:: powerci
#
# Copyright:: 2017-2021, Oregon State University
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
  include OSLGithubOauth::Helper
end

node.default['osl-jenkins']['secrets_item'] = 'powerci'
secrets = credential_secrets
admin_users = secrets['admin_users']
normal_users = secrets['normal_users']
client_id = secrets['oauth']['powerci']['client_id']
client_secret = secrets['oauth']['powerci']['client_secret']
powerci = node['osl-jenkins']['powerci']

ruby_block 'Set jenkins username/password if needed' do
  block do
    if ::File.exist?('/var/lib/jenkins/config.xml') &&
       ::File.foreach('/var/lib/jenkins/config.xml').grep(/GithubSecurityRealm/).any?
      node.run_state[:jenkins_username] = secrets['git']['powerci']['user']
      node.run_state[:jenkins_password] = secrets['git']['powerci']['token']
    end
  end
end

node.default['osl-jenkins']['plugins'].tap do |p|
  p['ansicolor'] = '0.5.2'
  p['build-monitor-plugin'] = '1.11+build.201701152243'
  p['build-timeout'] = '1.19'
  p['cloud-stats'] = '0.14'
  p['config-file-provider'] = '3.6'
  p['disable-github-multibranch-status'] = '1.1'
  p['docker-java-api'] = '3.0.14'
  p['docker-plugin'] = '1.1.9'
  p['email-ext'] = '2.66'
  p['emailext-template'] = '1.1'
  p['embeddable-build-status'] = '2.0.3'
  p['job-restrictions'] = '0.6'
  p['jquery'] = '1.12.4-0'
  p['label-linked-jobs'] = '5.1.2'
  p['nodelabelparameter'] = '1.7.2'
  p['openstack-cloud'] = '2.37'
  p['pipeline-githubnotify-step'] = '1.0.4'
  p['pipeline-multibranch-defaults'] = '1.1'
  p['resource-disposer'] = '0.12'
end

include_recipe 'osl-jenkins::master'

# Install directly from a URL since this doesn't appear to be included in the package data
jenkins_plugin 'copy-to-slave' do
  source 'http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/copy-to-slave/1.4.4/copy-to-slave-1.4.4.hpi'
  version '1.4.4'
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
      'fqdn' => ['fqdn'],
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

# openstack_cloud = add_openstack_cloud

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

# Disable code since we're not even using it and it may be causing other issues with Jenkins related to
# https://support.osuosl.org/Ticket/Display.html?id=30194
# jenkins_script 'Add OpenStack Cloud' do
#   command openstack_cloud
# end

jenkins_script 'Add GitHub OAuth config' do
  command github_oauth
end
