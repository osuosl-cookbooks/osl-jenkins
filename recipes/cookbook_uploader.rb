#
# Cookbook:: osl-jenkins
# Recipe:: cookbook_uploader
#
# Copyright:: 2015-2026, Oregon State University
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
chef_gem 'faraday-http-cache' do
  version '< 2.6'
  compile_time true
end

chef_gem 'git' do
  version '< 4'
  compile_time true
end

chef_gem 'octokit' do
  version '< 10'
  compile_time true
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

# Deploy yajl workaround lib needed by scripts using octokit
cookbook_file ::File.join(osl_jenkins_lib_path, 'yajl_workaround.rb') do
  source 'lib/yajl_workaround.rb'
  owner 'jenkins'
  group 'jenkins'
  mode '440'
end

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

# Cookbook CI: a GitHub Organization Folder discovers every repo in the org
# with a Jenkinsfile and runs its PRs/branches through the osl-pipelines
# shared library (replaces the hand-managed GHPRB linter jobs).
#
# NOTE: the 'cookbook_uploader' Jenkins credential this job and shared library
# reference is created out-of-band (Jenkins UI), NOT via JCasC. Do not add an
# osl_jenkins_password_credentials resource here: JCasC's credentials
# configurator is authoritative over the entire global credential store and
# would delete every out-of-band credential on the server on the next restart.
osl_jenkins_plugin 'github-branch-source' do
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

osl_jenkins_plugin 'generic-webhook-trigger' do
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

# readJSON for the uploader pipeline; not in the default plugin set, and its
# absence only surfaces at runtime, after a release is already published.
osl_jenkins_plugin 'pipeline-utility-steps' do
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

osl_jenkins_config 'shared_library' do
  source 'shared_library.yml.erb'
  variables(
    branch: node['osl-jenkins']['cookbook_uploader']['pipelines_branch'],
    repo: node['osl-jenkins']['cookbook_uploader']['pipelines_repo']
  )
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

osl_jenkins_job org_name do
  source 'jobs/cookbook_ci.groovy.erb'
  template true
  variables(
    job_name: org_name,
    org: org_name,
    repo_filter: node['osl-jenkins']['cookbook_uploader']['ci_repo_filter']
  )
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

# Label-driven release pipeline: one webhook-driven job for every repo in the
# org. Coexists with the per-repo freestyle jobs until cutover.
osl_jenkins_job 'cookbook-uploader' do
  source 'jobs/cookbook_uploader_pipeline.groovy.erb'
  template true
  variables(
    chef_repo: chef_repo,
    default_environments: node['osl-jenkins']['cookbook_uploader']['default_environments'].join(','),
    do_not_upload: node['osl-jenkins']['cookbook_uploader']['do_not_upload_cookbooks'].to_s,
    job_name: 'cookbook-uploader',
    org: org_name,
    pipelines_branch: node['osl-jenkins']['cookbook_uploader']['pipelines_branch'],
    pipelines_repo: node['osl-jenkins']['cookbook_uploader']['pipelines_repo'],
    trigger_token: jenkins_cred['trigger_token']
  )
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

osl_jenkins_job 'environment-bumper' do
  source 'jobs/environment_bumper_pipeline.groovy.erb'
  template true
  variables(
    chef_repo: chef_repo,
    default_environments: node['osl-jenkins']['cookbook_uploader']['default_environments'].join(','),
    job_name: 'environment-bumper',
    pipelines_branch: node['osl-jenkins']['cookbook_uploader']['pipelines_branch'],
    pipelines_repo: node['osl-jenkins']['cookbook_uploader']['pipelines_repo']
  )
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

# CI + deploy for the chef-repo itself: a multibranch pipeline discovers the
# Jenkinsfile in osuosl/chef-repo, validates every branch/PR with native
# commit statuses and uploads roles/environments from the primary branch.
# Replaces the GHPRB chef-repo-validator and chef-production freestyle jobs.
osl_jenkins_job 'chef-repo' do
  source 'jobs/chef_repo_pipeline.groovy.erb'
  template true
  variables(
    job_name: 'chef-repo',
    repo_owner: chef_repo.split('/').first,
    repo_name: chef_repo.split('/').last
  )
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

# Reconciles GitHub labels/webhooks org-wide on a schedule instead of during
# converge. Requires the out-of-band 'cookbook_uploader_trigger' secret-text
# credential — UI-created, never via JCasC (which wipes the credential store).
osl_jenkins_job 'github-sync' do
  source 'jobs/github_sync_pipeline.groovy.erb'
  template true
  variables(
    default_environments: node['osl-jenkins']['cookbook_uploader']['default_environments'].join(','),
    insecure_hook: node['osl-jenkins']['cookbook_uploader']['github_insecure_hook'].to_s,
    job_name: 'github-sync',
    org: org_name,
    pipelines_branch: node['osl-jenkins']['cookbook_uploader']['pipelines_branch'],
    pipelines_repo: node['osl-jenkins']['cookbook_uploader']['pipelines_repo'],
    repos: (node['osl-jenkins']['cookbook_uploader']['override_repos'] || []).join(','),
    webhook_endpoint: "https://#{public_address}/generic-webhook-trigger/invoke"
  )
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
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

# A repo with a Jenkinsfile has migrated to the label-driven pipeline: drop
# its legacy job config instead of creating it. Its legacy webhooks are
# removed by github-sync. (The leftover job on the Jenkins server itself
# still needs a one-time manual delete, as with archived repos.)
repo_names.each do |repo_name|
  job_name = "cookbook-uploader-#{org_name}-#{repo_name}"

  begin
    if repo_has_jenkinsfile?(git_cred['token'], org_name, repo_name)
      osl_jenkins_job job_name do
        action :delete
        notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
      end
      next
    end

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
  # Compile-phase GitHub call: degrade any API error to a warning so it can
  # never abort the converge; the loop is idempotent. On error the legacy job
  # is kept, never half-removed.
  rescue Octokit::Error => e
    Chef::Log.warn("GitHub setup for #{org_name}/#{repo_name} failed: #{e}")
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
