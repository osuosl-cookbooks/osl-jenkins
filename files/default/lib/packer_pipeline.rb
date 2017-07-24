#!/opt/chef/embedded/bin/ruby
require 'json'
require 'octokit'
require 'faraday-http-cache'

# Github API caching
stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache, serializer: Marshal, shared_cache: false
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack

# Library to process github payload for Packer Template Pipeline
class PackerPipeline
  def self.changed_files(json)
    github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'], auto_paginate: true)
    repo_path = json['repository']['full_name']
    issue_number = json['number']
    github.pull_request_files(repo_path, issue_number)
  end

  def self.find_dependent_templates(file)
    return [File.basename(file)] if file =~ /.json$/

    file = File.basename file
    dependent_templates = []

    # go to dir containing all images
    Dir.chdir(ENV['PACKER_TEMPLATES_DIR'] || './bento/packer')

    # Find if a shell script is referenced
    # iterate through images and look whether they refer to file
    Dir.glob('*.json') do |t|
      t_data = JSON.parse(File.read(t))

      next unless t_data.class.name == 'Hash'

      scripts = t_data.dig('provisioners', 0, 'scripts')

      next if scripts.nil?

      dependent_templates << t if scripts.any? { |f| f.include? file }
    end
    dependent_templates
  end

  def self.start
    d = JSON.parse(STDIN.read)

    templates = PackerPipeline.changed_files(d).map do |f|
      find_dependent_templates(f.filename)
    end.reduce(:+).uniq

    output = {
      'pr' => d['number']
    }

    %w(ppc64 x86_64).each do |arch|
      output[arch] = templates.select { |t| t.include? arch }.to_ary
    end
    output
  end
end
