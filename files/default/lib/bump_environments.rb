#!/opt/chef/embedded/bin/ruby
# Given a chef repo name, a cookbook name, a version to bump environments to,
# and a comma-separated list of environments passed as environment variables,
# bumps the cookbook to the given version in each of the environments (or all
# of them if no environments are specified) and creates a PR for it on Github.
# Also optionally takes a link to the PR that triggered the version bump.

require 'git'
require 'json'
require 'yaml'
require 'octokit'
require 'set'
require 'faraday-http-cache'

# Github API caching
stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache, serializer: Marshal, shared_cache: false
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack

# Library to bump environments
class BumpEnvironments
  @default_chef_envs = nil
  @default_chef_envs_word = nil
  @all_chef_envs_word = nil
  @github_token = nil
  @chef_repo = nil
  @cookbook = nil
  @version = nil
  @pr_link = nil
  @chef_envs = nil
  @chef_env_files = nil
  @is_default_envs = nil
  @is_all_envs = nil

  class << self
    attr_reader :default_chef_envs
    attr_reader :default_chef_envs_word
    attr_reader :all_chef_envs_word
    attr_reader :github_token
    attr_reader :chef_repo
  end

  def self.load_node_attr
    attr = YAML.load_file('bump_environments.yml')
    @default_chef_envs = attr['default_chef_envs'].freeze
    @default_chef_envs_word = attr['default_chef_envs_word'].freeze
    @all_chef_envs_word = attr['all_chef_envs_word'].freeze
    @github_token = attr['github_token'].freeze
    @chef_repo = attr['chef_repo'].freeze
  end

  def self.load_env
    @cookbook = ENV['cookbook']
    @version = ENV['version']
    @pr_link = ENV['pr_link']
    @chef_envs = ENV['envs'].split(',').to_set
  end

  def self.verify_chef_env
    BumpEnvironments.verify_default_chef_env 
    BumpEnvironments.verify_all_chef_env
  end

  def self.verify_default_chef_env
    if @chef_envs.include?(@default_chef_envs_word)
      @chef_envs.delete(@default_chef_envs_word)
      @chef_envs += @default_chef_envs
    end
    # Using the defaults if using nothing else
    @is_default_envs = @chef_envs == @default_chef_envs.to_set
  end

  def self.verify_all_chef_env
    if @chef_envs.include?(@all_chef_envs_word)
      @is_all_envs = true
      @chef_env_files = Dir.glob('environments/*.json')
      @chef_envs = @chef_env_files.map do |f|
        f.slice(%r{environments/(.*)\.json}, 1)
      end.to_set
    else
      @chef_env_files = @chef_envs.map { |e| "environments/#{e}.json" }
    end
  end

  def self.bump_env
    git = Git.open('.')
    BumpEnvironments.update_master(git)
    git_branch = BumpEnvironments.create_new_branch(git)
    BumpEnvironments.update_version
    BumpEnvironments.push_branch(git, git_branch)
    BumpEnvironments.create_pr(git, git_branch)
  end

  def self.update_master(git)
    git.branch('master').checkout
    git.pull('origin', 'master')
  end

  def self.create_new_branch(git)
    branch_hash = if @is_all_envs
                    'all-envs'
                  elsif @is_default_envs
                    'default-envs'
                  else
                    ''
                  end
    # Add a 5-digit hash of the version and envs so the branch names are unique.
    branch_hash += "-#{(@chef_envs.to_a << @version).join(',').hash % 100_000}"
    git_branch = "jenkins/#{@cookbook}-#{@version}-#{branch_hash}"
    git.branch(git_branch).checkout
    return git_branch
  end

  def self.update_version
    # Replace the old versions with the new versions
    @chef_env_files.each do |f|
      data = JSON.parse(::File.read(f))
      if data['cookbook_versions'].include?(@cookbook)
        data['cookbook_versions'][@cookbook] = "= #{@version}"
      end
      ::File.write(f, JSON.pretty_generate(data) + "\n")
    end
  end

  def self.push_branch(git, git_branch)
    # Commit and push our changes
    git.add(all: true)
    begin
      git.commit("Automatic version bump to v#{@version} by Jenkins")
    rescue Git::GitExecuteError
      $stderr.puts 'Unable to commit; were any changes actually made?'
    end
    git.push(git.remote('origin'), git_branch, tags: true, force: true)
  end

  def self.create_pr(git, git_branch)
    # Create the PR
    github = Octokit::Client.new(access_token: @github_token)
    title = "Bump '#{@cookbook}' cookbook to version #{@version}"
    body = "This automatically generated PR bumps the '#{@cookbook}' cookbook " \
      "to version #{@version} in "

    if @is_all_envs
      body += 'all environments.'
    elsif is_default_envs
      body += 'the default set of environments:' \
              "\n```\n#{@chef_envs.to_a.join("\n")}\n```"
    else
      body += 'the following environments:' \
              "\n```\n#{@chef_envs.to_a.join("\n")}\n```"
    end

    unless @pr_link.nil? || @pr_link.empty?
      body += "\nThis new version includes the changes from this PR: #{@pr_link}."
    end

    github.create_pull_request(@chef_repo, 'master', git_branch, title, body)
  end

  def self.start
    # TODO: Validate input
    BumpEnvironments.load_node_attr
    BumpEnvironments.load_env
    BumpEnvironments.verify_chef_env
    BumpEnvironments.bump_env
  end
end
