#!/opt/cinc/embedded/bin/ruby
require_relative '../lib/github_comment.rb'

# quit unless we get three command line arguments
unless ARGV.length == 3
  puts "Requires three arguments.\n"
  puts "Usage: github_comment.rb <repo_name> <issue_id> <comment_text>\n"
  exit
end

GithubComment.start
