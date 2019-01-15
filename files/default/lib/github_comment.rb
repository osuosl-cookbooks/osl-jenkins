#!/opt/chef/embedded/bin/ruby
require 'git'
require 'json'
require 'octokit'
require 'faraday-http-cache'

# Github API caching
stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache, serializer: Marshal, shared_cache: false
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack

# Given a repo, Github PR ID, and message text, add that text to the PR as
# a comment
class GithubComment
  @client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

  def self.add_comment(repo_name, issue_id, message)
    @client.add_comment(repo_name, issue_id, message)
  end

  def self.start
    repo_name = ARGV[0]
    issue_id = ARGV[1]
    message = ARGV[2]

    add_comment(repo_name, issue_id, message)
  end
end
