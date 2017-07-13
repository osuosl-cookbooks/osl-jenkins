#!/opt/chef/embedded/bin/ruby
require 'git'
require 'json'
require 'octokit'
require 'faraday-http-cache'
require 'pry'

# Github API caching
stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache, serializer: Marshal, shared_cache: false
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack

# Library to bump DNS zones
class PackerPipeline
  @commit_msg = "\n\n"
  @warning_msg = "Warning:\n\n"
  @warning = false

  class << self
    attr_reader :commit_msg
    @packer_templates_dir = ENV['PACKER_TEMPLATES_DIR'] || './bento/packer'
  end

  def self.add_commit_msg(msg)
    @commit_msg << msg
  end

  def self.add_warning_msg(msg)
    @warning = true
    @warning_msg << msg
  end

  def self.pr_merged(json)
    return unless json['action'] != 'closed' && json['pull_request']['merged'] != true
    puts 'Not a merged PR, skipping...'
    exit 0
  end

  def self.changed_files(json)
    github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'], auto_paginate: true)
    repo_path = json['repository']['full_name']
    issue_number = json['number']
    github.pull_request_files(repo_path, issue_number)
  end

  def self.find_dependent_templates(file)
    return [file] if file =~ /.json$/

    dependent_templates = []
  
    # go to dir containing all images
    Dir.chdir(@packer_templates_dir)
  
    # Find if a shell script is referenced
    # iterate through images and look whether they refer to file
    Dir.glob('*.json') do |t|
      t_data = JSON.parse(open(t))
      if (t_data.include? 'provisioners') && t_data['provisioners'].any?
        if t_data['provisioners'][0].include? 'scripts'
          dependent_templates << t if t_data['provisioners'][0]['scripts'].include? file
        end
      end
    end
    dependent_templates
  end

  def self.start
    d = JSON.parse(STDIN.read)
    PackerPipeline.pr_merged(d)

    PackerPipeline.changed_files(d).map(
      &method(:find_dependent_templates)
    ).reduce(:+)
  end
end
