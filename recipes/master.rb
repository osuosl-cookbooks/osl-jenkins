#
# Cookbook Name:: osl-jenkins
# Recipe:: master
#
# Copyright 2015, Oregon State University
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

node.default['jenkins']['master']['version'] = '2.46.1-1.1'
node.default['jenkins']['master']['listen_address'] = '127.0.0.1'

node.default['java']['jdk_version'] = '8'

# Manually set the jenkins java attribute to stop jenkins being restarted
# every chef run due to logic in
# https://github.com/chef-cookbooks/jenkins/blob/master/attributes/default.rb#L45-L53
node.set['jenkins']['java'] = 'java'

node.default['certificate'] = [{
  'wildcard' => {
    'cert_file' => 'wildcard.pem',
    'key_file' => 'wildcard.key',
    'chain_file' => 'wildcard-bundle.crt',
    'combined_file' => true
  }
}]

include_recipe 'java'
include_recipe 'jenkins::master'
include_recipe 'certificate::manage_by_attributes'
include_recipe 'osl-jenkins::haproxy'
include_recipe 'osl-haproxy::default'

if platform_family?('rhel')
  if node['platform_version'].to_i <= 6
    # CentOS 6 packages Git 1.7.1, but we need at least Git 1.7.9 for the
    # .git-credentials file to work (needed for the cookbook_uploader recipe),
    # and the Jenkins git plugin recommends 1.8.x. So we use 1.8.5.5, the
    # latest 1.8.x.
    node.set['git']['version'] = '1.8.5.5'
    node.set['git']['checksum'] = '106b480e2b3ae8b02e5b6b099d7a4049' \
                                  'f2b1128659ac81f317267d2ed134679f'
    include_recipe 'build-essential'
    include_recipe 'git::source'

    # Also create a symlink for when /usr/local/bin isn't in PATH.
    link '/usr/bin/git' do
      to '/usr/local/bin/git'
    end
  else
    # For CentOS 7 and up, the packaged version is new enough.
    include_recipe 'git::package'
  end
end

jenkins_command 'safe-restart' do
  action :nothing
end

{
  'credentials' => '2.1.13',
  'credentials-binding' => '1.11'
}.each do |p, v|
  jenkins_plugin p do
    version v
    notifies :execute, 'jenkins_command[safe-restart]'
  end
end

jenkins_plugin 'ssh-credentials' do
  version '1.12'
  notifies :execute, 'jenkins_command[safe-restart]', :immediately
end

secrets = credential_secrets

# This is necessary in order to create Jenkins jobs with security enabled.
node.run_state[:jenkins_private_key] = secrets['jenkins_private_key'] # ~FC001

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
