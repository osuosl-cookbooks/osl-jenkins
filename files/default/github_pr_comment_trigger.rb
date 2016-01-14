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
if match.nil?
  # Exit because it wasn't a valid bump request
  exit 0
end
level = match[2] || 'minor'

# Make sure the issue is a PR
unless d['issue'].key?('pull_request')
  puts 'Error: Cannot merge issue; can only merge PRs.'
  exit 1
end

# Make sure the PR isn't already merged
github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
reponame = d['repository']['name']
repopath = d['repository']['full_name']
pr = github.pull_request(repopath, d['issue']['number'])
if pr.merged
  puts 'Error: Cannot merge PR because it has already been merged.'
  exit 1
end

# Make sure the PR can be merged without conflicts
unless pr.mergeable
  puts 'Error: Cannot merge PR because it would create merge conflicts.'
  exit 1
end

# Merge the PR
pr.merge_pull_request
git = Git.open('.')
git.branch(GIT_BRANCH).checkout
git.pull(git.remote('origin'), GIT_BRANCH)

# Update the CHANGELOG.md?

# Bump the cookbook version in metadata.rb
version_regex = /^(version\s+)(["'])(\d+\.\d+\.\d+)\2$/
md = ::File.read(METADATA_FILE).gsub(version_regex) do
  m = Regexp.last_match # rubocop:disable Lint/UselessAssignment
  version = m(3).split('.')
  version[LEVELS[level]] = version[LEVELS[level]].to_i.next.to_s
  version = version.join('.')
  "#{m(1)}#{m(2)}#{version}#{m(2)}"
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
#`knife cookbook upload -o ../ #{reponame} --freeze`

# Close the PR
message = "Jenkins has merged this PR into `#{GIT_BRANCH}` and has " \
  "automatically performed a #{level}-level version bump to v#{version}.  " \
  'Have a nice day!'
pr.create_pull_request_comment(message)
pr.close_pull_request
