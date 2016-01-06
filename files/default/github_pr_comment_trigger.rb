#!/usr/bin/env ruby

# Takes a JSON payload from a Github PR issue webhook from stdin, reads the
# comment, and if it matches `!bump (major|minor|patch)?` (defaults to
# `minor`), merges the PR, bumps the Chef cookbook's metadata.rb, creates a
# version tag, and pushes up.

require 'git'
require 'json'
require 'octokit'
require 'pp'

GIT_BRANCH = 'master'
METADATA_FILE = 'metadata.rb'
COMMAND = '!bump'
LEVELS = {
  'major' => 0,
  'minor' => 1,
  'patch' => 2
}

d = JSON.load(STDIN.read)

# Check if we got a valid request and get the bump level
comment = d.fetch('comment', {}).fetch('body', '')
match = comment.match(/^#{COMMAND}( (#{LEVELS.keys.join('|')}))?$/, 2)
exit if match.nil?
level = match[2] || 'minor'

# Make sure the issue is a PR
exit unless d['issue'].has_key?('pull_request')

# Make sure the PR isn't already merged
github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
reponame = d['repository']['full_name']
puts reponame
pr = github.pull_request(reponame, d['issue']['number'])
exit if pr.merged

# Make sure the PR can be merged without conflicts
puts "mergeable: #{pr.mergeable}"
exit unless pr.mergeable

# Merge the PR
pr.merge_pull_request
git = Git.open('.')
git.branch(GIT_BRANCH).checkout

# Update the CHANGELOG.md?

# Bump the cookbook version in metadata.rb
md = ::File.read(METADATA_FILE).gsub(/^(version\s+)(["'])(\d+\.\d+\.\d+)\2$/) do |m|
  version = $3.split('.')
  version[LEVELS[level]] = version[LEVELS[level]].to_i.next.to_s
  version = version.join('.')
  "#{$1}#{$2}#{version}#{$2}"
end
::File.write(METADATA_FILE, md)
git.add(all: true)
git.commit("Automatic #{level}-level version bump to v#{version} by Jenkins")

# Create a version tag
git.tag("v#{version}")

# Push back to Github
git.push(git.remote('origin'), GIT_BRANCH)
git.push(git.remote('origin'), GIT_BRANCH, tags: true)

# Upload to the Chef server
#`knife cookbook upload -o ../ $(grep ^name metadata.rb| awk '{print $2;}' | tr -d \') --freeze`

# Close the PR
message = "Jenkins has merged this PR into `#{GIT_BRANCH}` and has automatically performed a #{level}-level version bump to v#{version}.  Have a nice day!"
pr.create_pull_request_comment(message)
pr.close_pull_request
