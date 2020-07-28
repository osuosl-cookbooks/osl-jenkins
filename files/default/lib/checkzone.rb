#!/opt/chef/embedded/bin/ruby
require 'git'
require 'json'
require 'octokit'
require 'open3'

# Library to check named dns zones
class CheckZone
  @issue_msg = "Zone syntax error(s) found:\n\n```\n"
  @syntax_error = false
  @github = nil
  @repo_path = nil
  @issue_number = nil

  class << self
    attr_reader :issue_msg
    attr_reader :repo_path
    attr_reader :issue_number
    attr_reader :syntax_error
  end

  def self.reset
    @issue_msg = "Zone syntax error(s) found:\n\n```\n"
    @syntax_error = false
    @github = nil
    @repo_path = nil
    @issue_number = nil
  end

  def self.add_issue_msg(msg)
    @issue_msg << msg
  end

  def self.github_init(json)
    @github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'], auto_paginate: true)
    @repo_path = json['repository']['full_name']
    @issue_number = json['number']
  end

  def self.commit_status(status)
    git_commit = ENV['GIT_COMMIT']
    return unless git_commit
    status_description = {
      'success' => 'named-checkzone has passed',
      'failure' => 'named-checkzone has found a syntax error',
    }

    options = {
      context: 'checkzone',
      target_url: "#{ENV['BUILD_URL']}console",
      description: status_description[status],
    }

    @github.create_status(@repo_path, git_commit, status, options)
  end

  def self.changed_files
    @github.pull_request_files(@repo_path, @issue_number)
  end

  def self.checkzone(zone_file)
    cmd = '/usr/sbin/named-checkzone ' + File.basename(zone_file.filename).gsub(/^db\./, '') +
          ' ' + zone_file.filename
    _stdin, stdout, wait_thr = Open3.popen2(cmd)
    return unless wait_thr.value.exitstatus > 0
    CheckZone.add_issue_msg(stdout.gets(nil))
    @syntax_error = true
  end

  def self.post_msg
    CheckZone.add_issue_msg("```\n")
    CheckZone.commit_status('failure')
    @github.add_comment(@repo_path, @issue_number, CheckZone.issue_msg)
    exit(1)
  end

  def self.pr_updated(json)
    return if json['action'] == 'synchronize' || json['action'] == 'opened'
    puts 'Not an updated or created PR, skipping...'
    exit(0)
  end

  def self.start
    d = JSON.parse(STDIN.read)
    CheckZone.pr_updated(d)
    CheckZone.github_init(d)
    CheckZone.changed_files.each do |f|
      CheckZone.checkzone(f) if File.basename(f.filename) =~ /^db\..*/
    end
    CheckZone.post_msg if @syntax_error
    CheckZone.commit_status('success') unless @syntax_error
  end
end
