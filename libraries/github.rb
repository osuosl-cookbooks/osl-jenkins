# Work around ffi-yajl 2.7.7 (shipped with Cinc 18) incorrectly depending on the 'yajl' gem (a logger, not a JSON
# parser). Both sawyer and multi_json detect the Yajl constant and try to use it as a JSON adapter, but Yajl.dump and
# Yajl::ParseError don't exist in the logger gem. Patch sawyer to rescue NameError and force multi_json to use
# json_gem.
def patch_yajl_workaround
  return if @_yajl_patched

  require 'sawyer'
  Sawyer::Serializer.define_singleton_method(:yajl) do
    require 'yajl'
    new(Yajl)
  rescue LoadError, NameError
  end

  require 'multi_json'
  MultiJson.use :json_gem

  @_yajl_patched = true
end

if defined?(Faraday::HttpCache)
  require 'faraday-http-cache'

  # Github API caching
  stack = Faraday::RackBuilder.new do |builder|
    builder.use Faraday::HttpCache, serializer: Marshal, shared_cache: false
    builder.use Octokit::Response::RaiseError
    builder.adapter Faraday.default_adapter
  end
  Octokit.middleware = stack
end

# Given a GitHub organization name and a GitHub API token with access to view the repositories in that org, returns a
# list of all repo names in the org that are not archived.
#
# @param github_token [String] GitHub API token with permissions to view
#   repositories on the given repo.
# @param org_name [String] Name of GitHub organization.
def collect_github_repositories(github_token, org_name)
  patch_yajl_workaround
  require 'octokit'
  github = Octokit::Client.new(access_token: github_token)
  github.auto_paginate = true

  github.org_repos(org_name).reject(&:archived?).map(&:name)
end

# Given a GitHub organization name and a GitHub API token with access to view the repositories in that org, returns a
# list of all repo names in the org that are archived.
#
# @param github_token [String] GitHub API token with permissions to view repositories on the given repo.
# @param org_name [String] Name of GitHub organization.
def collect_archived_github_repositories(github_token, org_name)
  patch_yajl_workaround
  require 'octokit'
  github = Octokit::Client.new(access_token: github_token)
  github.auto_paginate = true

  github.org_repos(org_name).select(&:archived?).map(&:name)
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
# rubocop:disable Metrics/ParameterLists
def set_up_github_push(github_token, org_name, repo_name, job_name,
                       trigger_token, insecure_hook, auth_user = nil,
                       auth_token = nil)
  patch_yajl_workaround
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
  # rubocop:disable Layout/MultilineOperationIndentation
  existing_hooks = hooks.select do |h|
    h['name'] == type &&
    h['events'] == events &&
    h['config']['content_type'] == content_type
  end
  # rubocop:enable Layout/MultilineOperationIndentation

  hook_config = {
    url: url,
    content_type: content_type,
    insecure_ssl: insecure_hook,
  }
  hook_options = {
    events: events,
    active: true,
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
# rubocop:enable
