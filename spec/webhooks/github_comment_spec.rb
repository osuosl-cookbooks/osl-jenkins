require 'rspec'
require 'rspec/mocks'
require 'tempfile'
require 'pathname'
require_relative '../../files/default/lib/github_comment'

describe GithubComment do
  context '#start' do
    it 'tells octokit to add a comment' do
      stub_const('ARGV', ['org/repo', 1, 'Test comment.'])

      expect_any_instance_of(Octokit::Client)
        .to receive(:add_comment).with('org/repo', 1, 'Test comment.')

      GithubComment.start
    end
  end
end
