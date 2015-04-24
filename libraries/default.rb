def collect_github_repositories(token = {}, org = nil)
  if ::ObjectSpace.const_defined?('Chef')
    # Chef exists! Lets make sure octokit is installed..
    chef_gem 'octokit'
  end

  require 'octokit'

  client = Octokit::Client.new(token)
  client.auto_paginate = true

  client.org_repos(org).map(&:name)
end
