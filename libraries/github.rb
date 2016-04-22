def collect_github_repositories(github_token, org)
  if ::ObjectSpace.const_defined?('Chef')
    # Chef exists! Lets make sure Octokit is installed.
    chef_gem 'octokit'
  end

  require 'octokit'

  github = Octokit::Client.new(access_token: github_token)
  github.auto_paginate = true

  github.org_repos(org).map(&:name)
end

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
def set_up_github_push(github_token, org_name, repo_name, job_name,
                       trigger_token)
  if ::ObjectSpace.const_defined?('Chef')
    # Chef exists! Lets make sure Octokit is installed.
    chef_gem 'octokit'
  end

  require 'octokit'
  require 'pp'

  github = Octokit::Client.new(access_token: github_token)

  repo_path = "#{org_name}/#{repo_name}"
  hooks = github.hooks(repo_path)
  type = 'web'
  events = ['issue_comment']
  content_type = 'form'
  url = "https://#{public_address}/job/#{job_name}" \
    "/buildWithParameters?token=#{trigger_token}"

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
    insecure_ssl:
      node['osl-jenkins']['cookbook_uploader']['github_insecure_hook']
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
