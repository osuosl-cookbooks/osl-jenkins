require 'rspec'
require 'rspec/mocks'
require 'tempfile'
require 'pathname'
require_relative '../../files/default/lib/github_comment'

describe GithubComment do
  context '#start' do
    it 'tells octokit to add a comment' do
      allow(ARGV).to receive(:[]).and_return('org/repo', 1, 'Test comment.')

      expect_any_instance_of(Octokit::Client)
        .to receive(:add_comment).with('org/repo', 1, 'Test comment.')

      GithubComment.start
    end

    it 'creates the directory' do
      expect(chef_run).to create_directory('/var/chef/cache/github_comment').with(recursive: true)
    end

    it 'creates the github_comment jenkins job' do
      expect(chef_run).to create_jenkins_job('github_comment').with(config: '/var/chef/cache/github_comment/config.xml')
    end

    it 'creates the github pr job config file' do
      expect(chef_run).to create_template('/var/chef/cache/github_comment/config.xml')
        .with(
          source: 'github_comment.config.xml.erb',
          mode: 0440
        )
    end
  end
end
