#
# Cookbook:: osl-jenkins
# Recipe:: ibmz_ci
#
# Copyright:: 2018-2021, Oregon State University
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
      node.run_state[:jenkins_username] = secrets['git']['ibmz_ci']['user']
      node.run_state[:jenkins_password] = secrets['git']['ibmz_ci']['token']
    end
  end
end

node.default['osl-jenkins']['plugins'].tap do |p|
  p['ansicolor'] = '1.0.0'
  p['build-monitor-plugin'] = '1.12+build.201809061734'
  p['build-timeout'] = '1.20'
  p['cloud-stats'] = '0.27'
  p['config-file-provider'] = '3.8.0'
  p['disable-github-multibranch-status'] = '1.2'
  p['docker-java-api'] = '3.1.5.2'
  p['docker-plugin'] = '1.2.2'
  p['email-ext'] = '2.83'
  p['emailext-template'] = '1.2'
  p['embeddable-build-status'] = '2.0.3'
  p['extended-read-permission'] = '3.2'
  p['job-restrictions'] = '0.8'
  p['jquery'] = '1.12.4-1'
  p['label-linked-jobs'] = '6.0.1'
  p['nodelabelparameter'] = '1.8.1'
  p['pipeline-githubnotify-step'] = '1.0.5'
  p['pipeline-multibranch-defaults'] = '2.1'
  p['resource-disposer'] = '0.15'
end

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
      'fqdn' => ['fqdn'],
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
