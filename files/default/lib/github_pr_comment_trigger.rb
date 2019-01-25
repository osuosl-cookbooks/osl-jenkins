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
require 'octokit'
require 'faraday-http-cache'

require_relative 'github_pr_comment_trigger_var'

AUTHORIZED_USER = $AUTHORIZED_USER
AUTHORIZED_ORGS = $AUTHORIZED_ORGS
AUTHORIZED_TEAMS = $AUTHORIZED_TEAMS
GITHUB_TOKEN = $GITHUB_TOKEN
DO_NOT_UPLOAD_COOKBOOKS = $DO_NOT_UPLOAD_COOKBOOKS
NON_BUMP_MESSAGE = $NON_BUMP_MESSAGE

METADATA_FILE = 'metadata.rb'.freeze
CHANGELOG_FILE = 'CHANGELOG.md'.freeze
COMMAND = '!bump'.freeze
LEVELS = {
  'major' => 0,
  'minor' => 1,
  'patch' => 2
}.freeze

# Github API caching
stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache, serializer: Marshal, shared_cache: false
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack

# Library for Github PR comment trigger
class GithubPrCommentTrigger
  @github = Octokit::Client.new(access_token: GITHUB_TOKEN)
  @level = nil
  @envs = nil
  @repo_name = nil
  @repo_path = nil
  @issue_number = nil
  @pr = nil
  
  # Given a GitHub client, a GitHub username, and a GitHub team (of the form
  # "$ORGNAME/$TEAMNAME"), returns whether the given user is a member of the
  # given team.
  def self.team_member?(team, user)
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

  # Given a version string of the form 'x.x.x' and a level 0, 1, or 2, increments
  # the specified level and returns the new version string.  All numbers to the
  # right of the bumped number are reset to 0.
  def self.inc_version(v)
    v = v.split('.')
    v[@level] = v[@level].to_i.next.to_s
    (@level + 1...3).each { |i| v[i] = '0' }
    v.join('.')
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

  def self.verify_comment_creation(d)
    unless d['action'] == 'created'
      # This isn't an error, we just don't need to do anything, so we exit with a 0.
      $stderr.puts NON_BUMP_MESSAGE
      exit 0
    end
  end

  def self.verify_valid_request(d)
    # Check if we got a valid request and get the bump level
    comment = d.fetch('comment', {}).fetch('body', '')
    match = comment.match(/^#{COMMAND} (#{LEVELS.keys.join('|')})( \S+(,\S+)*)?$/)
    if match.nil?
      # This isn't an error, we just don't need to do anything, so we exit with a 0.
      $stderr.puts NON_BUMP_MESSAGE
      exit 0
    end
    @level = match[1]
    @envs = match[2]
    @envs.strip! unless @envs.nil?
  end

  def self.verify_issue_is_pr(d)
    # Make sure the issue is a PR
    unless d['issue'].key?('pull_request')
      abort 'Error: Cannot merge issue; can only merge PRs.'
    end
  end

  def self.verify_pr_not_merged(d)
    # Make sure the PR isn't already merged
    @repo_name = d['repository']['name']
    @repo_path = d['repository']['full_name']
    @issue_number = d['issue']['number']
    @pr = @github.pull_request(@repo_path, @issue_number)
    abort 'Error: Cannot merge PR because it has already been merged.' if @pr.merged
  end

  def self.verify_pr_mergeable(d)
    # Make sure the PR can be merged without conflicts
    unless @pr.mergeable
      abort 'Error: Cannot merge PR because it would create merge conflicts.'
    end
  end

  def self.verify_commenter_permission(d)
    # Make sure the commenter has permission to perform the merge. The user has
    # permission if their username is in AUTHORIZED_USERS, if one of the
    # organizations they are in is in AUTHORIZED_ORGS, or if one of the teams they
    # are in is in AUTHORIZED_TEAMS. If AUTHORIZED_USERS, AUTHORIZED_ORGS, and
    # AUTHORIZED_TEAMS are all empty, then everyone has permission.
    user = d['comment']['user']['login']
    unless (AUTHORIZED_USERS.empty? &&
           AUTHORIZED_ORGS.empty? &&
           AUTHORIZED_TEAMS.empty?) ||
           AUTHORIZED_USERS.include?(user) ||
           AUTHORIZED_ORGS.detect { |o| @github.organization_member?(o, user) } ||
           AUTHORIZED_TEAMS.detect { |t| GithubPrCommentTrigger.team_member?(t, user) }
      abort "Error: Cannot merge PR because user '#{user}' is not authorized."
    end
  end


  def self.merge_pr
    # Merge the PR
    @github.merge_pull_request(@repo_path, @issue_number)

    # Delete the old branch
    pr_branch = @pr['head']['ref']
    @github.delete_branch(@repo_path, pr_branch)
  end

  def self.update_version
    # Set up the git gem
    git = Git.open('.')
    base_branch = GithubPrCommentTrigger.pull_updated_branch(git)
    GithubPrCommentTrigger.update_metadata
    GithubPrCommentTrigger.update_changelog
    GithubPrCommentTrigger.push_updates(git, base_branch)
    GithubPrCommentTrigger.close_pr(base_branch)
    GithubPrCommentTrigger.return_envvars
  end

  def self.pull_updated_branch(git)
    # Pull the updated base branch down
    base_branch = @pr['base']['ref']
    git.branch(base_branch).checkout
    git.pull(git.remote('origin'), base_branch)
    return base_branch
  end

  def self.update_metadata
    # Bump the cookbook version in metadata.rb
    # Match the line that looks like `version   "1.2.3"`
    version = '' # Get the version variable in scope
    version_regex = /^(version\s+)(["'])(\d+\.\d+\.\d+)\2$/
    md = ::File.read(METADATA_FILE).gsub(version_regex) do
      key = Regexp.last_match(1) # The "version" key and some whitespace
      quote = Regexp.last_match(2) # The type of quotation mark used, e.g. " vs '
      version = GithubPrCommentTrigger.inc_version(Regexp.last_match(3))
      # Reconstruct the version line by using the new version with the same spacing
      # and quotation mark types as before
      "#{key}#{quote}#{version}#{quote}"
    end
    ::File.write(METADATA_FILE, md)

  end

  def self.update_changelog
    # Update the CHANGELOG.md with the PR's title
    entry = "#{version} (#{Time.now.strftime('%Y-%m-%d')})"
    entry += "\n" + '-' * entry.length
    entry += "\n- #{d['issue']['title']}\n\n"
    # Inject the new entry above the first one we find
    cl = ::File.read(CHANGELOG_FILE).sub(/^(.*\d+\.\d+\.\d+)/, entry + '\1')
    ::File.write(CHANGELOG_FILE, cl)
  end

  def self.push_updates(git, base_branch)
    # Commit changes
    git.add(all: true)
    git.commit("Automatic #{@level}-level version bump to v#{version} by Jenkins")

    # Create a version tag
    git.add_tag("v#{version}")

    # Push back to Github
    git.push(git.remote('origin'), base_branch, tags: true)

    # Upload to the Chef server, freezing, ignoring dependencies
    $stderr.puts "Uploading #{@repo_name} cookbook to the Chef server..."
    unless DO_NOT_UPLOAD_COOKBOOKS
      `knife cookbook upload #{@repo_name} --freeze -o ../`
    end
  end

  def self.close_pr(base_branch)
    # Close the PR
    message = "Jenkins has merged this PR into `#{base_branch}` and has " \
      "automatically performed a #{@level}-level version bump to v#{version}.  " \
      'Have a nice day!'
    @github.add_comment(@repo_path, @issue_number, message)
  end

  def self.return_envvars
    # Return some environment variables for the Chef environment bumper job to use.
    # If we got no envs, the file won't be created and the job won't be triggered.
    unless @envs.nil?
      ::File.write('envvars',
                   "cookbook=#{@repo_name}\n" \
                   "version=#{version}\n" \
                   "envs=#{@envs}\n" \
                   "pr_link=#{d['issue']['html_url']}")
    end
  end

  def self.start
    GithubPrCommentTrigger.verify
    GithubPrCommentTrigger.merge_pr
    GithubPrCommentTrigger.update_version
  end
end
