#!/opt/chef/embedded/bin/ruby

# Takes a JSON payload from a Github PR issue webhook from stdin, reads the
# comment, and if it matches `!bump (major|minor|patch)`, merges the PR, bumps
# the Chef cookbook's metadata.rb, creates a version tag, and pushes up.
#
# Additionally, will pass environments to bump to the environment bumper job if
# a comma-delimited list of environments (or a * for all of them) is appended
# to the !bump command, e.g.
#   !bump patch *
#   !bump minor production
#   !bump major dev,staging

require 'git'
require 'json'
require 'yaml'
require 'octokit'
require 'faraday-http-cache'

# Github API caching
stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache, serializer: Marshal, shared_cache: false
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack

# Library for Github PR comment trigger
class GithubPrCommentTrigger
  @github = nil
  @authorized_user = nil
  @authorized_orgs = nil
  @authorized_teams = nil
  @github_token = nil
  @do_not_upload_cookbooks = nil
  @non_bump_message = nil
  @level = nil
  @envs = nil
  @repo_name = nil
  @repo_path = nil
  @issue_number = nil
  @pr = nil
  @version = nil
  @metadata_file = 'metadata.rb'.freeze
  @changelog_file = 'CHANGELOG.md'.freeze
  @command = '!bump'.freeze
  @levels = {
    'major' => 0,
    'minor' => 1,
    'patch' => 2
  }.freeze

  class << self
    attr_reader :github
    attr_reader :authorized_user
    attr_reader :authorized_orgs
    attr_reader :authorized_teams
    attr_reader :github_token
    attr_reader :do_not_upload_cookbooks
    attr_reader :non_bump_message
    attr_reader :level
    attr_reader :envs
    attr_reader :repo_name
    attr_reader :repo_path
    attr_reader :issue_number
    attr_reader :pr
    attr_reader :version
    attr_reader :metadata_file
    attr_reader :changelog_file
    attr_reader :command
    attr_reader :levels
  end
  
  def self.load_node_attr
    attr = YAML.load_file('github_pr_comment_trigger.yml')
    @authorized_user = attr['authorized_user']
    @authorized_orgs = attr['authorized_orgs']
    @authorized_teams = attr['authorized_teams']
    @github_token = attr['github_token']
    @non_bump_message = attr['non_bump_message']
    @do_not_upload_cookbooks = attr['do_not_upload_cookbooks']
  end

  def self.setup_github
    @github = Octokit::Client.new(access_token: @github_token)
  end

  def self.verify_comment_creation(d)
    unless d['action'] == 'created'
      $stderr.puts @non_bump_message
      exit 0
    end
  end

  def self.verify_valid_request(d)
    comment = d.fetch('comment', {}).fetch('body', '')
    match = comment.match(/^#{@command} (#{@levels.keys.join('|')})( \S+(,\S+)*)?$/)
    if match.nil?
      $stderr.puts @non_bump_message
      exit 0
    end
    @level = match[1]
    @envs = match[2]
    @envs.strip! unless @envs.nil?
  end

  def self.verify_issue_is_pr(d)
    unless d['issue'].key?('pull_request')
      abort 'Error: Cannot merge issue; can only merge PRs.'
    end
  end

  def self.verify_pr_not_merged(d)
    @repo_name = d['repository']['name']
    @repo_path = d['repository']['full_name']
    @issue_number = d['issue']['number']
    @pr = @github.pull_request(@repo_path, @issue_number)
    if @pr.merged
      abort 'Error: Cannot merge PR because it has already been merged.'
    end
  end

  def self.verify_pr_mergeable(d)
    unless @pr.mergeable
      abort 'Error: Cannot merge PR because it would create merge conflicts.'
    end
  end

  def self.team_member?(team, user)
    # Given a GitHub client, a GitHub username, and a GitHub team (of the form
    # "$ORGNAME/$TEAMNAME"), returns whether the given user is a member of the
    # given team.
    org_name, team_name = team.split('/')
    team_id = @github.organization_teams(org_name).find do |t|
      t.name.casecmp(team_name) == 0
    end.id
    begin
      @github.team_membership(team_id, user)
    rescue Octokit::NotFound
      false
    end
  end

  def self.verify_commenter_permission(d)
    # Make sure the commenter has permission to perform the merge. The user has
    # permission if their username is in @authorized_user, if one of the
    # organizations they are in is in @authorized_orgs, or if one of the teams they
    # are in is in @authorized_teams. If @authorized_user, @authorized_orgs, and
    # @authorized_teams are all empty, then everyone has permission.
    user = d['comment']['user']['login']
    unless (@authorized_user.empty? &&
           @authorized_orgs.empty? &&
           @authorized_teams.empty?) ||
           @authorized_user.include?(user) ||
           @authorized_orgs.detect { |o| @github.organization_member?(o, user) } ||
           @authorized_teams.detect { |t| GithubPrCommentTrigger.team_member?(t, user) }
      abort "Error: Cannot merge PR because user '#{user}' is not authorized."
    end
  end

  def self.merge_pr
    @github.merge_pull_request(@repo_path, @issue_number)

    # Delete the old branch
    pr_branch = @pr.head.ref
    @github.delete_branch(@repo_path, pr_branch)
  end

  def self.pull_updated_branch(git)
    # Pull the updated base branch down
    base_branch = @pr.base.ref
    git.branch(base_branch).checkout
    git.pull(git.remote('origin'), base_branch)
    return base_branch
  end

  def self.inc_version(v)
    # Given a version string of the form 'x.x.x' and a level 0, 1, or 2, increments
    # the specified level and returns the new version string.  All numbers to the
    # right of the bumped number are reset to 0.
    level = @levels[@level]
    v = v.split('.')
    v[level] = v[level].to_i.next.to_s
    (level + 1...3).each { |i| v[i] = '0' }
    v.join('.')
  end

  def self.update_metadata(metadata_file)
    # Bump the cookbook version in metadata.rb
    # Match the line that looks like `version   "1.2.3"`
    @version = '' # Get the version variable in scope
    version_regex = /^(version\s+)(["'])(\d+\.\d+\.\d+)\2$/
    md = ::File.read(metadata_file).gsub(version_regex) do
      # The "version" key and some whitespace
      key = Regexp.last_match(1)
      # The type of quotation mark used, e.g. " vs '
      quote = Regexp.last_match(2) 
      @version = GithubPrCommentTrigger.inc_version(Regexp.last_match(3))
      # Reconstruct the version line by using the new version with the same spacing
      # and quotation mark types as before
      "#{key}#{quote}#{@version}#{quote}"
    end
    ::File.write(metadata_file, md)
  end

  def self.update_changelog(changelog_file)
    # Update the CHANGELOG.md with the PR's title
    entry = "#{@version} (#{Time.now.strftime('%Y-%m-%d')})"
    entry += "\n" + '-' * entry.length
    entry += "\n- #{d['issue']['title']}\n\n"
    # Inject the new entry above the first one we find
    cl = ::File.read(changelog_file).sub(/^(.*\d+\.\d+\.\d+)/, entry + '\1')
    ::File.write(changelog_file, cl)
  end

  def self.push_updates(git, base_branch)
    # Commit changes
    git.add(all: true)
    git.commit("Automatic #{@level}-level version bump to v#{@version} by Jenkins")

    # Create a version tag
    git.add_tag("v#{@version}")

    # Push back to Github
    git.push(git.remote('origin'), base_branch, tags: true)

    # Upload to the Chef server, freezing, ignoring dependencies
    $stderr.puts "Uploading #{@repo_name} cookbook to the Chef server..."
    unless @do_not_upload_cookbooks
      `knife cookbook upload #{@repo_name} --freeze -o ../`
    end
  end

  def self.close_pr(base_branch)
    # Close the PR
    message = "Jenkins has merged this PR into `#{base_branch}` and has " \
      "automatically performed a #{@level}-level version bump to v#{@version}.  " \
      'Have a nice day!'
    @github.add_comment(@repo_path, @issue_number, message)
  end

  def self.return_envvars
    # Return some environment variables for the Chef environment bumper job to use.
    # If we got no envs, the file won't be created and the job won't be triggered.
    unless @envs.nil?
      ::File.write('envvars',
                   "cookbook=#{@repo_name}\n" \
                   "version=#{@version}\n" \
                   "envs=#{@envs}\n" \
                   "pr_link=#{d['issue']['html_url']}")
    end
  end

  def self.verify
    d = JSON.load(STDIN.read)
    GithubPrCommentTrigger.verify_comment_creation(d)
    GithubPrCommentTrigger.verify_valid_request(d)
    GithubPrCommentTrigger.verify_issue_is_pr(d)
    GithubPrCommentTrigger.verify_pr_not_merged(d)
    GithubPrCommentTrigger.verify_pr_mergeable(d)
    GithubPrCommentTrigger.verify_commenter_permission(d)
  end

  def self.update_version
    # Set up the git gem
    git = Git.open('.')
    base_branch = GithubPrCommentTrigger.pull_updated_branch(git)
    GithubPrCommentTrigger.update_metadata(@metadata_file)
    GithubPrCommentTrigger.update_changelog(@changelog_file)
    GithubPrCommentTrigger.push_updates(git, base_branch)
    GithubPrCommentTrigger.close_pr(base_branch)
    GithubPrCommentTrigger.return_envvars
  end

  def self.start
    GithubPrCommentTrigger.load_node_attr
    GithubPrCommentTrigger.setup_github
    GithubPrCommentTrigger.verify
    GithubPrCommentTrigger.merge_pr
    GithubPrCommentTrigger.update_version
  end
end
