def collect_github_repositories(token = {}, org)
  if ::ObjectSpace.const_defined?('Chef')
    # Chef exists! Lets make sure Octokit is installed.
    chef_gem 'octokit'
  end

  require 'octokit'

  github = Octokit::Client.new(token)
  github.auto_paginate = true

  github.org_repos(org).map(&:name)
end

def set_up_github_push(token = {}, orgname, reponame, jobname, trigger_token)
  if ::ObjectSpace.const_defined?('Chef')
    # Chef exists! Lets make sure Octokit is installed.
    chef_gem 'octokit'
  end

  require 'octokit'
  require 'pp'

  github = Octokit::Client.new(token)

  repopath = "#{orgname}/#{reponame}"
  hooks = github.hooks(repopath)
  type = 'web'
  events = ['issue_comment']
  content_type = 'form'
  url = "https://#{node['jenkins']['master']['host']}" \
    ":#{node['jenkins']['master']['port']}/job/#{jobname}/" \
    "buildWithParameters?token=#{trigger_token}"

  # Get all hooks that we may have created in the past
  existing_hooks = hooks.select do |h|
    h['name'] == type &&
    h['events'] == events &&
    h['config']['content_type'] == content_type
  end

  # If the hook exists and is outdated, delete it.
  current_hook_exists = false
  existing_hooks.each do |h|
    if h['url'] != url
      github.delete_hook(repopath, h['id'])
    else
      current_hook_exists = true
    end
  end

  # Create a new hook unless an up-to-date one already exists
  unless current_hook_exists
    github.create_hook(
      repopath,
      type,
      {
        :url => url,
        :content_type => content_type
      },
      {
        :events => events,
        :active => true
      }
    )
  end
end
