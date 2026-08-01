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
org_name = node['osl-jenkins']['cookbook_uploader']['org']
chef_repo = node['osl-jenkins']['cookbook_uploader']['chef_repo']

jenkins_cred = credential_secrets['jenkins']['cookbook_uploader']

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

# CI + deploy for the private data_bags repo on GitLab: validates every
# branch/MR, uploads bags from the primary branch. Replaces the
# gitlab-plugin data_bags freestyle job. The server config manages the
# GitLab webhook; both credentials it references (API token, SSH checkout
# key) are out-of-band (UI-created), never JCasC.
osl_jenkins_plugin 'gitlab-branch-source' do
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

osl_jenkins_config 'gitlab_server' do
  source 'gitlab_server.yml.erb'
  variables(
    name: node['osl-jenkins']['cookbook_uploader']['gitlab_server_name'],
    url: node['osl-jenkins']['cookbook_uploader']['gitlab_server_url'],
    credential_id: node['osl-jenkins']['cookbook_uploader']['gitlab_api_credential']
  )
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

osl_jenkins_job 'data-bags' do
  source 'jobs/data_bags_pipeline.groovy.erb'
  template true
  variables(
    checkout_credential: node['osl-jenkins']['cookbook_uploader']['data_bags_credential'],
    job_name: 'data-bags',
    project_owner: node['osl-jenkins']['cookbook_uploader']['data_bags_project'].split('/').first,
    project_path: node['osl-jenkins']['cookbook_uploader']['data_bags_project'],
    server_name: node['osl-jenkins']['cookbook_uploader']['gitlab_server_name']
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

# Retired: the label-driven pipeline replaced the per-repo freestyle jobs,
# the freestyle environment bumper and their trigger scripts. Config cleanup
# only; the server-side job is deleted by hand. Drop these resources once
# they have converged everywhere.
osl_jenkins_job "environment-bumper-#{chef_repo.tr('/', '-')}" do
  action :delete
  notifies :restart, 'osl_jenkins_service[cookbook_uploader]', :delayed
end

%w(github_pr_comment_trigger.rb bump_environments.rb).each do |s|
  file ::File.join(osl_jenkins_bin_path, s) do
    action :delete
  end
end
