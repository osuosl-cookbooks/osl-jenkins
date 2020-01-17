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
  def self.new
    @github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'], auto_paginate: true)
    @repo_path = 'osuosl/packer-templates'
    self
  end

  # find the changed files associated with the PR
  def self.changed_files(json)
    issue_number = json['number'].nil? ? json['issue']['number'] : json['number']
    @github.pull_request_files(@repo_path, issue_number)
  end

  # get the latest git sha for a PR
  def self.get_commit(pr)
    @github.pull_request(@repo_path, pr).head.sha
  end

  # get commit status for a sha
  def self.get_status(pr)
    ref = get_commit(pr)
    status = @github.combined_status(@repo_path, ref)
    status.state
  end

  # add comment to the PR and abort
  def self.abort_comment(comment, pr)
    @github.add_comment(@repo_path, pr, comment)
    puts comment
    exit(1)
  end

  # If file is a template, return it in an array.
  # If it receives a script, then it locates all
  # templates that use that script and returns them in an array.
  def self.find_dependent_templates(file)
    return [File.basename(file)] if file =~ /.json$/

    dependent_templates = []

    # go to dir containing all images
    Dir.chdir(ENV['PACKER_TEMPLATES_DIR'] || '/home/alfred/workspace/packer-templates')

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
        scripts = ssp['scripts'].nil? ? [] : ssp['scripts']
        dependent_templates << t if scripts.any? { |f| f.include? file }
      end
    end
    dependent_templates
  end

  # update status for the PR from the final_results given by the pipeline
  # the final_results is a JSON hash containing all the templates that were processed.
  def self.commit_status(final_results)
    git_commit = ENV['GIT_COMMIT']
    return unless git_commit

    final_results = JSON.parse(final_results)

    # we are processing a JSON array which looks like
    # {
    #   'arch': {
    #       'template_name' : {
    #             'linter' : 0,
    #             'builder': 0,
    #             'deploy_test' : 0,
    #             'taster' : 0,
    #         }
    #   }
    # }
    final_status = {}

    final_results.keys.each do |arch|
      final_results[arch].keys.each do |t|
        # create a context array per template
        final_status[t] = {
          options: {
            context: t,
            # TODO: make this point to the specific job's console output
            target_url: "#{ENV['BUILD_URL']}console",
          },
        }

        # we will set the GitHub status based on the first stage that we encounter
        # as failed. The Pipeline automatically ignores a template once it has
        # failed a previous stage, so we do it this way.
        final_results[arch][t].keys.each do |stage|
          if final_results[arch][t][stage].to_i != 0
            final_status[t][:state] = 'failure'
            final_status[t][:options][:description] = "#{stage} failed!"
            break
          end

          final_status[t][:state] = 'success'
          final_status[t][:options][:description] = "All passed! #{final_results[arch][t]}"
        end
        # set status
        @github.create_status(@repo_path, git_commit, final_status[t][:state], final_status[t][:options])
      end
    end
    final_status
  end

  def self.production_deploy(pr_num)
    pr = @github.pull_request(@repo_path, pr_num)
    abort_comment('Error: Cannot merge PR because it has already been merged.', pr_num) if pr.merged
    abort_comment('Error: Cannot merge PR because it would create merge conflicts.', pr_num) unless pr.mergeable
    @github.merge_pull_request(@repo_path, pr_num)
    @github.delete_branch(@repo_path, pr.head.ref)
  end

  def self.process_payload(payload)
    payload = JSON.parse(payload)
    # Iterate through all the changed files and get an array of affected templates.
    # find_dependent_templates always returns an array of strings, so I use
    # .reduce to stitch those arrays together by doing the + on arrays of dependent
    # templates for each script. Finally .uniq will ensure we don't get the same
    # template twice in the array
    templates = changed_files(payload).map do |f|
      find_dependent_templates(f.filename)
    end.reduce(:+).uniq

    # Include the PR number
    pr_num = payload['number'].nil? ? payload['issue']['number'] : payload['number']
    event_type = payload['number'].nil? ? 'issue' : 'pull_request'
    pr_state = get_status(pr_num)
    output = {
      'pr' => pr_num,
      'event_type' => event_type,
      'pr_state' => pr_state,
    }

    # Create hash of templates and the architectures associated with them.
    %w(aarch64 ppc64 x86_64).each do |arch|
      output[arch] = templates.select { |t| t.include? arch }.to_ary
    end

    # Return the hash so the executeable can handle printing.
    output
  end
end
