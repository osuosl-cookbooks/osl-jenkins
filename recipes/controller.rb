#
# Cookbook:: osl-jenkins
# Recipe:: controller
#
# Copyright:: 2015-2022, Oregon State University
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

# Don't automatically update jenkins
node.override['yum-cron']['yum_parameter'] = '-x jenkins'

node.default['jenkins']['master']['version'] = '2.289.1-1.1'
node.default['jenkins']['master']['listen_address'] = '127.0.0.1'
node.default['jenkins']['executor']['protocol'] = 'http'

# Manually set the jenkins java attribute to stop jenkins being restarted
# every chef run due to logic in
# https://github.com/chef-cookbooks/jenkins/blob/master/attributes/default.rb#L45-L53
node.default['jenkins']['java'] = 'java'

node.default['certificate'] = [{
  'wildcard' => {
    'cert_file' => 'wildcard.pem',
    'key_file' => 'wildcard.key',
    'chain_file' => 'wildcard-bundle.crt',
    'combined_file' => true,
  },
}]

include_recipe 'yum-plugin-versionlock'

yum_version_lock 'jenkins' do
  version_split = node['jenkins']['master']['version'].split('-')
  version version_split[0]
  release version_split[1]
  arch 'noarch'
end

openjdk_pkg_install '8'

include_recipe 'jenkins::master'

edit_resource(:package, 'jenkins') do
  flush_cache(before: true)
end

certificate_manage 'wildcard' do
  cert_file 'wildcard.pem'
  key_file 'wildcard.key'
  chain_file 'wildcard-bundle.crt'
  notifies :restart, 'haproxy_service[haproxy]'
end
include_recipe 'osl-jenkins::haproxy'
include_recipe 'osl-haproxy::default'

include_recipe 'osl-git'

jenkins_command 'safe-restart' do
  action :nothing
end

include_recipe 'osl-jenkins::plugins'

secrets = credential_secrets

# This is necessary in order to create Jenkins jobs with security enabled.
node.run_state[:jenkins_username] = secrets['jenkins_username']
node.run_state[:jenkins_password] = secrets['jenkins_password']

# Add git credentials into Jenkins
secrets['git'].to_a.each do |git_id, cred|
  jenkins_password_credentials cred['user'] do
    id git_id
    password cred['token']
  end
end

# Add ssh credentials into Jenkins
secrets['ssh'].to_a.each do |ssh_id, cred|
  jenkins_private_key_credentials cred['user'] do
    id ssh_id
    private_key cred['private_key']
    passphrase cred['passphrase']
  end
end

# Make a git config
git_config_path = ::File.join(node['jenkins']['master']['home'], '.gitconfig')

cookbook_file git_config_path do
  source 'gitconfig'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
end

[
  node['osl-jenkins']['bin_path'],
  node['osl-jenkins']['lib_path'],
].each do |d|
  directory d do
    recursive true
  end
end
