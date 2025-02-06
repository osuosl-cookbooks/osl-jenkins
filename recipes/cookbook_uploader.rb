#
# Cookbook:: osl-jenkins
# Recipe:: cookbook_uploader
#
# Copyright:: 2015-2025, Oregon State University
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
%w(
  faraday-http-cache
  git
  octokit
).each do |p|
  chef_gem p do
    compile_time true
  end
end

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
%w(github_pr_comment_trigger.rb bump_environments.rb).each do |s|
  template ::File.join(osl_jenkins_bin_path, s) do
    source "#{s}.erb"
    mode '0550'
    owner 'jenkins'
    group 'jenkins'
    variables(
      all_environments_word: node['osl-jenkins']['cookbook_uploader']['all_environments_word'],
      authorized_orgs: node['osl-jenkins']['cookbook_uploader']['authorized_orgs'],
      authorized_teams: node['osl-jenkins']['cookbook_uploader']['authorized_teams'],
      authorized_users: node['osl-jenkins']['cookbook_uploader']['authorized_users'],
      chef_repo: chef_repo,
      default_environments: node['osl-jenkins']['cookbook_uploader']['default_environments'],
      default_environments_word: node['osl-jenkins']['cookbook_uploader']['default_environments_word'],
      do_not_upload_cookbooks: node['osl-jenkins']['cookbook_uploader']['do_not_upload_cookbooks'],
      github_token: git_cred['token'],
      non_bump_message: non_bump_message
    )
  end
end

# Create cookbook-uploader jobs for each repo
execute_shell = 'echo $payload | ' + ::File.join(osl_jenkins_bin_path, 'github_pr_comment_trigger.rb')
repo_names = node['osl-jenkins']['cookbook_uploader']['override_repos']
repo_names = collect_github_repositories(git_cred['token'], org_name) if repo_names.nil? || repo_names.empty?
archived_repo_names = node['osl-jenkins']['cookbook_uploader']['override_archived_repos']
archived_repo_names = collect_archived_github_repositories(git_cred['token'], org_name) if archived_repo_names.nil? || archived_repo_names.empty?

osl_jenkins_service 'cookbook_uploader' do
  action :nothing
end

env_job_name = "environment-bumper-#{chef_repo.tr('/', '-')}"

osl_jenkins_job env_job_name do
  source 'jobs/environment-bumper.groovy.erb'
  template true
  variables(
    all_environments_word: node['osl-jenkins']['cookbook_uploader']['all_environments_word'],
    default_environments_word: node['osl-jenkins']['cookbook_uploader']['default_environments_word'],
    execute_shell: "#{osl_jenkins_bin_path}/bump_environments.rb",
    github_url: "https://github.com/#{chef_repo}",
    job_name: env_job_name,
    trigger_token: jenkins_cred['trigger_token']
  )
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

repo_names.each do |repo_name|
  job_name = "cookbook-uploader-#{org_name}-#{repo_name}"
  osl_jenkins_job job_name do
    source 'jobs/cookbook_uploader.groovy.erb'
    template true
    variables(
      execute_shell: execute_shell,
      github_url: "https://github.com/#{org_name}/#{repo_name}",
      job_name: job_name,
      non_bump_message: non_bump_message,
      trigger_token: jenkins_cred['trigger_token']
    )
    notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
  end

  begin
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
  rescue Octokit::InternalServerError, Octokit::BadGateway, Octokit::ServerError => e
    Chef::Log.warn("Unable to connect to Github: #{e}")
  end
end

# Delete archived repositories from jenkins configs
# NOTE: This will not remove it from the Jenkins server, just the JASC config
archived_repo_names.each do |repo_name|
  job_name = "cookbook-uploader-#{org_name}-#{repo_name}"
  osl_jenkins_job job_name do
    action :delete
    notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
  end
end
