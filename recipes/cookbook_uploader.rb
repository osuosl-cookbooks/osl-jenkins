#
# Cookbook Name:: osl-jenkins
# Recipe:: cookbook-uploader
#
# Copyright (C) 2015 Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# We need git stuff, plus build-token-root for triggering from Github PRs
package 'git'
%w(git github build-token-root).each do |p|
  jenkins_plugin p do
    notifies :restart, 'service[jenkins]'
  end
end

orgname = node['osl-jenkins']['cookbook_uploader']['org']

# Note: The `github_user` field is used for Git pull/push over https in
# conjuction with the token, rather than an SSH key.
begin
  secrets = Chef::EncryptedDataBagItem.load(
    node['osl-jenkins']['cookbook_uploader']['databag'],
    node['osl-jenkins']['cookbook_uploader']['secrets_item']
  )
# TODO: Rescue a specific exception?
rescue
  Chef::Log.warn(
    'Unable to load databag ' \
    "'#{node['osl-jenkins']['cookbook_uploader']['databag']}:" \
    "#{node['osl-jenkins']['cookbook_uploader']['secrets_item']}'; " \
    'falling back to attributes.'
  )
  secrets = node['osl-jenkins']['cookbook_uploader']['credentials']
end

node.run_state[:jenkins_username] = secrets['jenkins_user']
node.run_state[:jenkins_password] = secrets['jenkins_pass']

# TODO: Remove after done testing?
# Create a Git credentials file so we can access repos using our API token.
# This obviates the need for an ssh key.
git_credentials_path = ::File.join(node['jenkins']['master']['home'],
                                   '.git-credentials')
directory ::File.dirname(git_credentials_path) do
  recursive true
end
file git_credentials_path do
  content "https://#{secrets['github_user']}:" \
    "#{secrets['github_token']}@github.com"
  mode '0400'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
end

# Also make a git config so that the credentials file actually gets used.
git_config_path = ::File.join(node['jenkins']['master']['home'],
                              '.gitconfig')
file git_config_path do
  content "[credential]\n    helper = store"
  mode '0664'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
end

# Install necessary gems
%w(git octokit).each do |g|
  chef_gem g
end

# Copy over the github_pr_comment_trigger script
github_pr_comment_trigger_path = \
  ::File.join(node['osl-jenkins']['cookbook_uploader']['scripts_path'],
              'github_pr_comment_trigger.rb')
directory ::File.dirname(github_pr_comment_trigger_path) do
  recursive true
end
cookbook_file github_pr_comment_trigger_path do
  source 'github_pr_comment_trigger.rb'
  mode '0550'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
end

execute_shell = "echo $payload | #{github_pr_comment_trigger_path}"

# reponames = collect_github_repositories(secrets, orgname)
reponames = ['lanparty'] # For testing
reponames.each do |reponame|
  xml = ::File.join(Chef::Config[:file_cache_path],
                    orgname, reponame, 'config.xml')
  directory ::File.dirname(xml) do
    recursive true
  end
  template xml do
    source 'cookbook-uploader.config.xml.erb'
    variables(
      github_url: "https://github.com/#{orgname}/#{reponame}",
      trigger_token: secrets['trigger_token'],
      execute_shell: execute_shell
    )
  end
  jobname = "cookbook-uploader-#{orgname}-#{reponame}"
  jenkins_job jobname do
    config xml
    action [:create, :enable]
  end
  set_up_github_push(
    secrets['github_token'],
    orgname,
    reponame,
    jobname,
    secrets['trigger_token']
  )
end
