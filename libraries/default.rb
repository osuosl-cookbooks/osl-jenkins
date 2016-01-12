def collect_github_repositories(token = {}, org = nil)
  if ::ObjectSpace.const_defined?('Chef')
    # Chef exists! Lets make sure Octokit is installed.
    chef_gem 'octokit'
  end

  require 'octokit'

  github = Octokit::Client.new(token)
  github.auto_paginate = true

  github.org_repos(org).map(&:name)
end

def set_up_github_push(token = {}, orgname = nil, reponame = nil)
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

  hook_exists = hooks.detect do |h|
    h['name'] == type &&
    h['events'] == events &&
    h['config']['content_type'] == content_type
  end

  unless hook_exists
    github.create_hook(
      repopath,
      type,
      {
        :url => "https://#{node['jenkins']['master']['host']}" \
                ":#{node['jenkins']['master']['port']}",
        :content_type => content_type
      },
      {
        :events => events,
        :active => true
      }
    )
  end
end

#set_up_github_push({ access_token: '' },
#                   'osuosl-cookbooks',
#                   'lanparty')
