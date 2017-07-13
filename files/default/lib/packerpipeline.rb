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

# Library to process github payload for Packer Template Pipeline
class PackerPipeline
  class << self
    @packer_templates_dir = ENV['PACKER_TEMPLATES_DIR'] || './bento/packer'
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

    templates = PackerPipeline.changed_files(d).map(
      &method(:find_dependent_templates)
    ).reduce(:+).uniq

    %w(ppc64 x86_64).each do |arch|
      print "images_affected_#{arch} = [ " \
         "#{templates.select { |t| t.include? arch }.join(' ')} ]"
    end
  end
end
