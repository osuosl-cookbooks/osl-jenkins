# Given a GitHub organization name and a GitHub API token with access to view
# the repositories in that org, returns a list of all repo names in the org.
#
# @param github_token [String] GitHub API token with permissions to view
#   repositories on the given repo.
# @param org_name [String] Name of GitHub organization.
def collect_github_repositories(github_token, org_name)
  require 'octokit'

  github = Octokit::Client.new(access_token: github_token)
  github.auto_paginate = true

  github.org_repos(org_name).map(&:name)
end

# Sets up a GitHub trigger for the Jenkins cookbook uploader job.  It will
# trigger whenever a comment is made on a PR/issue and will send a JSON payload
# of the comment to the specified Jenkins job, using the given trigger token to
# authenticate with Jenkins (otherwise, the trigger would be ignored).
#
# @param github_token [String] GitHub API token with permissions to create
#   hooks on the given repo.
# @param org_name [String] Name of GitHub organization.
# @param repo_name [String] Name of GitHub repo within the organization.
# @param job_name [String] Name of the Jenkins job to trigger.
# @param trigger_token [String] A trigger token to authenticate with Jenkins.
# @param insecure_hook [Boolean] Whether to allow triggering Jenkins over
#   insecure connection (useful for testing).
# @param auth_user [String] Jenkins user for authentication with Jenkins server
# @param auth_token [String] Jenkins user api token for authentication with
#   Jenkins server
#
# rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/ParameterLists
def set_up_github_push(github_token, org_name, repo_name, job_name,
                       trigger_token, insecure_hook, auth_user = nil,
                       auth_token = nil)
  require 'octokit'

  github = Octokit::Client.new(access_token: github_token)

  repo_path = "#{org_name}/#{repo_name}"
  hooks = github.hooks(repo_path)
  type = 'web'
  events = ['issue_comment']
  content_type = 'form'
  url = 'https://'
  url.concat("#{auth_user}:#{auth_token}@") if auth_user && auth_token
  url.concat("#{public_address}/job/#{job_name}" \
    "/buildWithParameters?token=#{trigger_token}")

  # Get all hooks that we may have created in the past
  # rubocop:disable Style/MultilineOperationIndentation
  existing_hooks = hooks.select do |h|
    h['name'] == type &&
    h['events'] == events &&
    h['config']['content_type'] == content_type
  end
  # rubocop:enable Style/MultilineOperationIndentation

  hook_config = {
    url: url,
    content_type: content_type,
    insecure_ssl: insecure_hook
  }
  hook_options = {
    events: events,
    active: true
  }

  # Create a hook if none exist, or update the existing one(s).
  if existing_hooks.empty?
    github.create_hook(repo_path, type, hook_config, hook_options)
  else
    existing_hooks.each do |h|
      github.edit_hook(repo_path, h['id'], type, hook_config, hook_options)
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
