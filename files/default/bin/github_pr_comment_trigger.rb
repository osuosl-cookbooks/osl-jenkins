#!/opt/chef/embedded/bin/ruby
require_relative '../lib/github_pr_comment_trigger'

GithubPrCommentTrigger.start
