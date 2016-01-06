def collect_github_repositories(token = {}, org = nil)
  if ::ObjectSpace.const_defined?('Chef')
    # Chef exists! Lets make sure Octokit is installed.
    chef_gem 'octokit'
  end

  require 'octokit'

  client = Octokit::Client.new(token)
  client.auto_paginate = true

  client.org_repos(org).map(&:name)
end

def set_up_github_push(token = {}, orgname = nil, reponame = nil)
  if ::ObjectSpace.const_defined?('Chef')
    # Chef exists! Lets make sure Octokit is installed.
    chef_gem 'octokit'
  end

  require 'octokit'
  require 'pp'

  client = Octokit::Client.new(token)

  repopath = "#{orgname}/#{reponame}"
  repo = client.repo(repopath)
  pp(repo.hooks)
  repo.hooks
  client.create_hook(
    repopath,
    'jenkins_autobump',
    {
      :url => 'http://something.com/webhook',
      :content_type => 'json'
    },
    {
      :events => ['push', 'pull_request'],
      :active => true
    }
  )
end

set_up_github_push({ access_token: '' },
                   'osuosl-cookbooks',
                   'lanparty')
