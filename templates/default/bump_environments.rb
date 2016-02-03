#!/opt/chef/embedded/bin/ruby

# Given a cookbook name, a version to bump environments to, and a
# comma-separated list of environments passed as environment variables, bumps
# the cookbook to the given version in each of the environments (or all of them
# if no environments are specified) and creates a PR for it on Github.

require 'git'
require 'json'
require 'octokit'
require 'pp' # TODO: Remove pp after done debugging

# TODO: Validate input

orgname = '<%= @org_name %>'
cookbook = ENV['cookbook']
version = ENV['version']

# Only bump in the chef environments specified
chef_envs = ENV['envs'].split(',').map { |s| s + '.json' }
# If no envs are specified, bump all of them
if chef_envs.empty?
  all_envs = true
  chef_envs = Dir::glob('*.json')
end

# Replace the old versions with the new versions
chef_envs.each do |e|
  data = JSON.load(::File.read(e))
  data['cookbook_versions'][cookbook] = "= #{version}"
  ::File.write(e, JSON.dump(data))
end

# Create a new branch, then commit and push our changes
Git.configure do |config|
  config.binary_path = '<%= @git_path %>'
end
git = Git.open('.')
env_names = chef_envs.each { |e| e.slice!('.json') }
git_branch = "jenkins/bump-#{cookbook}-to-#{version}-in-#{env_names.join(',')}"
git.branch(git_branch).checkout
git.add(all: true)
git.commit("Automatic #{level}-level version bump to v#{version} by Jenkins")
git.push(git.remote('origin'), git_branch, tags: true)

# Create the PR
github = Octokit::Client.new(access_token: '<%= @github_token %>')
repopath = "#{orgname}/#{cookbook}"
title = "Bump '#{cookbook}' cookbook to version #{version}"
body = "This automatically generated PR bumps the '#{cookbook}' cookbook " \
  "to version #{version} in "
if all_envs
  body += 'all environments.'
else
  body += "the following environments:\n```#{env_names.join("\n")}```"
end
github.create_pull_request(repopath, 'master', git_branch, title, body)
