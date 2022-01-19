#
# Cookbook:: osl-jenkins
# Recipe:: cookbook_uploader
#
# Copyright:: 2015-2022, Oregon State University
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
%w(git octokit faraday-http-cache).each do |p|
  chef_gem p do
    compile_time true
  end
end
include_recipe 'osl-jenkins::controller'

org_name = node['osl-jenkins']['cookbook_uploader']['org']
chef_repo = node['osl-jenkins']['cookbook_uploader']['chef_repo']

# A build is triggered on every Github comment, but will only succeed if the
# comment was a bump request.  This message is displayed if the comment was not
# a bump request and the build will be marked as unstable.
non_bump_message = 'Exiting because comment was not a bump request'.freeze

secrets = credential_secrets
git_cred = secrets['git']['cookbook_uploader']
jenkins_cred = secrets['jenkins']['cookbook_uploader']

# Copy over scripts for Jenkins to run
bin_path = node['osl-jenkins']['bin_path']
%w(github_pr_comment_trigger.rb bump_environments.rb).each do |s|
  template ::File.join(bin_path, s) do
    source "#{s}.erb"
    mode '0550'
    owner node['jenkins']['master']['user']
    group node['jenkins']['master']['group']
    variables(
      authorized_users:
        node['osl-jenkins']['cookbook_uploader']['authorized_users'],
      authorized_orgs:
        node['osl-jenkins']['cookbook_uploader']['authorized_orgs'],
      authorized_teams:
        node['osl-jenkins']['cookbook_uploader']['authorized_teams'],
      github_token: git_cred['token'],
      chef_repo: chef_repo,
      default_environments:
        node['osl-jenkins']['cookbook_uploader']['default_environments'],
      default_environments_word:
        node['osl-jenkins']['cookbook_uploader']['default_environments_word'],
      all_environments_word:
        node['osl-jenkins']['cookbook_uploader']['all_environments_word'],
      non_bump_message: non_bump_message,
      do_not_upload_cookbooks:
        node['osl-jenkins']['cookbook_uploader']['do_not_upload_cookbooks']
    )
  end
end

# Create cookbook-uploader jobs for each repo
execute_shell = 'echo $payload | ' +
                ::File.join(bin_path, 'github_pr_comment_trigger.rb')
repo_names = node['osl-jenkins']['cookbook_uploader']['override_repos']
repo_names = collect_github_repositories(git_cred['token'], org_name) if repo_names.nil? || repo_names.empty?
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
      trigger_token: jenkins_cred['trigger_token'],
      execute_shell: execute_shell,
      non_bump_message: non_bump_message
    )
  end
  job_name = "cookbook-uploader-#{org_name}-#{repo_name}"
  jenkins_job job_name do
    config xml
    action :create
  end
  set_up_github_push(
    git_cred['token'],
    org_name,
    repo_name,
    job_name,
    jenkins_cred['trigger_token'],
    node['osl-jenkins']['cookbook_uploader']['github_insecure_hook'],
    jenkins_cred['user'],
    jenkins_cred['api_token']
  )
end

# Also create a job for bumping versions in environments
execute_shell = ::File.join(bin_path, 'bump_environments.rb')
xml = ::File.join(Chef::Config[:file_cache_path],
                  chef_repo, 'config.xml')
directory ::File.dirname(xml) do
  recursive true
end
template xml do
  source 'environment-bumper.config.xml.erb'
  variables(
    github_url: "https://github.com/#{chef_repo}",
    trigger_token: jenkins_cred['trigger_token'],
    execute_shell: execute_shell,
    default_environments_word:
      node['osl-jenkins']['cookbook_uploader']['default_environments_word'],
    all_environments_word:
      node['osl-jenkins']['cookbook_uploader']['all_environments_word']
  )
end
job_name = "environment-bumper-#{chef_repo.tr('/', '-')}"
jenkins_job job_name do
  config xml
  action :create
end
