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
  include OSLGithubOauth::Helper
end

node.default['osl-jenkins']['secrets_item'] = 'ibmz_ci'
secrets = credential_secrets
admin_users = secrets['admin_users']
normal_users = secrets['normal_users']
client_id = secrets['oauth']['ibmz_ci']['client_id']
client_secret = secrets['oauth']['ibmz_ci']['client_secret']

ruby_block 'Set jenkins username/password if needed' do
  block do
    if ::File.exist?('/var/lib/jenkins/config.xml') &&
       ::File.foreach('/var/lib/jenkins/config.xml').grep(/GithubSecurityRealm/).any?
      node.run_state[:jenkins_username] = secrets['git']['ibmz_ci']['user'] # ~FC001
      node.run_state[:jenkins_password] = secrets['git']['ibmz_ci']['token'] # ~FC001
    end
  end
end

node.default['osl-jenkins']['plugins'].tap do |p|
  p['ansicolor'] = '0.5.2'
  p['build-monitor-plugin'] = '1.11+build.201701152243'
  p['build-timeout'] = '1.19'
  p['cloud-stats'] = '0.11'
  p['config-file-provider'] = '3.6'
  p['docker-java-api'] = '3.0.14'
  p['docker-plugin'] = '1.1.3'
  p['email-ext'] = '2.66'
  p['emailext-template'] = '1.1'
  p['embeddable-build-status'] = '1.9'
  p['job-restrictions'] = '0.6'
  p['jquery'] = '1.12.4-0'
  p['label-linked-jobs'] = '5.1.2'
  p['nodelabelparameter'] = '1.7.2'
  p['pipeline-multibranch-defaults'] = '1.1'
  p['resource-disposer'] = '0.12'
end

include_recipe 'osl-jenkins::master'

github_oauth =
  add_github_oauth(
    client_id,
    client_secret,
    admin_users,
    normal_users
  )

jenkins_script 'Add GitHub OAuth config' do
  command github_oauth
end
