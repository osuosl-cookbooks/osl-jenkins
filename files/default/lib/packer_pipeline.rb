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
  # find the changed files associated with the PR
  def self.changed_files(json)
    github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'], auto_paginate: true)
    repo_path = json['repository']['full_name']
    issue_number = json['number']
    github.pull_request_files(repo_path, issue_number)
  end

  # If file is a template, return it in an array.
  # If it receives a script, then it locates all
  # templates that use that script and returns them in an array.
  def self.find_dependent_templates(file)
    return [File.basename(file)] if file =~ /.json$/

    file = File.basename file
    dependent_templates = []

    # go to dir containing all images
    Dir.chdir(ENV['PACKER_TEMPLATES_DIR'] || '/home/alfred/workspace')

    # Find if a shell script is referenced
    # iterate through images and look whether they refer to file
    Dir.glob('*.json') do |t|
      t_data = JSON.parse(File.read(t))

      # .dig fails if it tries to index an array with a string, which is ridiculous.
      # This will fail on other json files that start with in an array.
      # I suppose this helps more in testing than anything, since there aren't going
      # to be other json files in the repo.
      next unless t_data.class.name == 'Hash'

      # select only shell scripts provisioners as only they refer to files that we worry about
      shell_script_provisioners = t_data.dig('provisioners')
      # .dig returns nil if it doesn't find that path in the hash.
      next if shell_script_provisioners.nil?

      shell_script_provisioners.select! { |p| p['type'] == 'shell' }

      # if any of the shell script provisioners includes the shell script in question,
      # this is a dependent template

      shell_script_provisioners.each do |ssp|
        dependent_templates << t if ssp['scripts'].any? { |f| f.include? file }
      end
    end
    dependent_templates
  end

  def self.start
    d = JSON.parse(STDIN.read)

    # Iterate through all the changed files and get an array of affected templates.
    # find_dependent_templates always returns an array of strings, so I use
    # .reduce to stitch those arrays together.
    templates = PackerPipeline.changed_files(d).map do |f|
      find_dependent_templates(f.filename)
    end.reduce(:+).uniq

    # Include the PR number
    output = {
      'pr' => d['number']
    }

    # Create hash of templates and the architectures associated with them.
    %w(ppc64 x86_64).each do |arch|
      output[arch] = templates.select { |t| t.include? arch }.to_ary
    end

    # Return the hash so the executeable can handle printing.
    output
  end
end
