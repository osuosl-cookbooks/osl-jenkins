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

def public_address
  node.fetch('cloud', {}).fetch('public_ipv4', nil) || node['fqdn']
end

# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
def set_up_github_push(github_token, orgname, reponame, jobname, trigger_token)
  if ::ObjectSpace.const_defined?('Chef')
    # Chef exists! Lets make sure Octokit is installed.
    chef_gem 'octokit'
  end

  require 'octokit'
  require 'pp'

  github = Octokit::Client.new(access_token: github_token)

  repopath = "#{orgname}/#{reponame}"
  hooks = github.hooks(repopath)
  type = 'web'
  events = ['issue_comment']
  content_type = 'form'
  url = "https://#{public_address}/job/#{jobname}" \
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
    github.create_hook(repopath, type, hook_config, hook_options)
  else
    existing_hooks.each do |h|
      github.edit_hook(repopath, h['id'], type, hook_config, hook_options)
    end
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength
