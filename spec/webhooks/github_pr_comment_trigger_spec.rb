require 'rspec'
require 'rspec/mocks'
require 'tempfile'
require 'pathname'
require 'yaml'
require_relative '../../files/default/lib/github_pr_comment_trigger'

module SpecHelper
  def fixture_path(name)
    File.join(File.expand_path('../../fixtures', __FILE__), name)
  end

  def open_fixture(name)
    File.read(fixture_path(name))
  end

  def open_json(name)
    JSON.parse(open_fixture(name))
  end

  def open_yaml(name)
    YAML.load_file(fixture_path(name))
  end

  def tempfile(file)
    tempfile = Tempfile.new("#{Pathname.new(file).basename}-rspec")
    tempfile.write(::File.read(file))
    tempfile.rewind
    tempfile
  end
end

RSpec.configure do |c|
  c.include SpecHelper
end

describe GithubPrCommentTrigger do
  let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }

  before :each do
    allow(Octokit::Client).to receive(:new) { github_mock }
    allow(YAML).to receive(:load_file).with('github_pr_comment_trigger.yml')
      .and_return(open_yaml('github_pr_comment_trigger.yml'))
  end

  context 'default class variables' do
    it 'check frozen default class variables' do
      expect(GithubPrCommentTrigger.metadata_file).to eql('metadata.rb')
      expect(GithubPrCommentTrigger.changelog_file).to eql('CHANGELOG.md')
      expect(GithubPrCommentTrigger.command).to eql('!bump')
      expect(GithubPrCommentTrigger.levels).to include('major' => 0, 'minor' => 1, 'patch' => 2)
    end
  end

  context '#load_node_attr' do
    it 'load node attributes' do
      expect(GithubPrCommentTrigger.authorized_user).to be_nil
      expect(GithubPrCommentTrigger.authorized_orgs).to be_nil
      expect(GithubPrCommentTrigger.authorized_teams).to be_nil
      expect(GithubPrCommentTrigger.github_token).to be_nil
      expect(GithubPrCommentTrigger.non_bump_message).to be_nil
      expect(GithubPrCommentTrigger.do_not_upload_cookbooks).to be_nil
      GithubPrCommentTrigger.load_node_attr
      expect(GithubPrCommentTrigger.authorized_user).to match_array([])
      expect(GithubPrCommentTrigger.authorized_orgs).to match_array([])
      expect(GithubPrCommentTrigger.authorized_teams).to match_array(['osuosl-cookbooks/staff'])
      expect(GithubPrCommentTrigger.github_token).to eql('github_token')
      expect(GithubPrCommentTrigger.non_bump_message).to eql('Exiting because comment was not a bump request')
      expect(GithubPrCommentTrigger.do_not_upload_cookbooks).to be true
    end
  end

  context '#verify _comment_creation' do
    it 'has created action' do

    end
    it 'does not have created action' do

  end
end
