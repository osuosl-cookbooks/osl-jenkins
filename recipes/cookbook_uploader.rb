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

# git and github: for git
# build-token-root: for triggering from Github PRs
# text-finder: for marking unstable builds (used in this case to mark builds
#   where no action was taken)
# parameterized-trigger: for triggering other jobs (e.g. the environment-bumper
#   job) with parameters
%w(git github build-token-root parameterized-trigger text-finder).each do |p|
  jenkins_plugin p do
    notifies :restart, 'service[jenkins]'
  end
end

org_name = node['osl-jenkins']['cookbook_uploader']['org']
chef_repo = node['osl-jenkins']['cookbook_uploader']['chef_repo']

# A build is triggered on every Github comment, but will only succeed if the
# comment was a bump request.  This message is displayed if the comment was not
# a bump request and the build will be marked as unstable.
non_bump_message = 'Exiting because comment was not a bump request'

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

# This is necessary in order to create Jenkins jobs with security enabled.
node.run_state['jenkins_username'] = secrets['jenkins_user']
node.run_state['jenkins_password'] = secrets['jenkins_pass']

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

# Make a git config
git_config_path = ::File.join(node['jenkins']['master']['home'],
                              '.gitconfig')
file git_config_path do
  content "[push]\n    default = current\n" \
          "[user]\n    name = JenkinsCI\n" \
          "[credential]\n    helper = store"
  mode '0664'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
end

# Install necessary gems
%w(git octokit).each do |g|
  chef_gem g
end

# Copy over scripts for Jenkins to run
scripts_path = node['osl-jenkins']['cookbook_uploader']['scripts_path']
directory scripts_path do
  recursive true
end
%w(github_pr_comment_trigger.rb bump_environments.rb).each do |s|
  template ::File.join(scripts_path, s) do
    source "#{s}.erb"
    mode '0550'
    owner node['jenkins']['master']['user']
    group node['jenkins']['master']['group']
    variables(
      git_path: ::File.join(node['git']['prefix'], 'bin', 'git'),
      github_token: secrets['github_token'],
      org_name: org_name,
      chef_repo: chef_repo,
      non_bump_message: non_bump_message
    )
  end
end

# Create cookbook-uploader jobs for each repo
execute_shell = 'echo $payload | ' +
  ::File.join(scripts_path, 'github_pr_comment_trigger.rb') +
  ' > envvars'
repo_names = node['osl-jenkins']['cookbook_uploader']['override_repos']
if repo_names.nil? or repo_names.empty?
  repo_names = collect_github_repositories(secrets, org_name)
end
repo_names.each do |repo_name|
  xml = ::File.join(Chef::Config[:file_cache_path],
                    org_name, repo_name, 'config.xml')
  directory ::File.dirname(xml) do
    recursive true
  end
  template xml do
    source 'cookbook-uploader.config.xml.erb'
    variables(
      github_url: "https://github.com/#{org_name}/#{repo_name}",
      trigger_token: secrets['trigger_token'],
      execute_shell: execute_shell,
      non_bump_message: non_bump_message
    )
  end
  job_name = "cookbook-uploader-#{org_name}-#{repo_name}"
  jenkins_job job_name do
    config xml
    action [:create, :enable]
  end
  set_up_github_push(
    secrets['github_token'],
    org_name,
    repo_name,
    job_name,
    secrets['trigger_token']
  )
end

# Also create a job for bumping versions in environments
execute_shell = "#{::File.join(scripts_path, 'bump_environments.rb')}"
xml = ::File.join(Chef::Config[:file_cache_path],
                  chef_repo, 'config.xml')
directory ::File.dirname(xml) do
  recursive true
end
template xml do
  source 'environment-bumper.config.xml.erb'
  variables(
    github_url: "https://github.com/#{chef_repo}",
    trigger_token: secrets['trigger_token'],
    execute_shell: execute_shell
  )
end
job_name = "environment-bumper-#{chef_repo.gsub('/', '-')}"
jenkins_job job_name do
  config xml
  action [:create, :enable]
end
