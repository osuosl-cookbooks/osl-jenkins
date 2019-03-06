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
  let(:not_bump_message) { 'Exiting because comment was not a bump request' }
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

  context '#verify_comment_creation' do
    it 'has created action' do
      expect{ GithubPrCommentTrigger.verify_comment_creation(open_json('bump_major.json')) }
        .to_not output.to_stderr
      expect{ GithubPrCommentTrigger.verify_comment_creation(open_json('bump_patch.json')) }
        .to_not output.to_stderr
      expect{ GithubPrCommentTrigger.verify_comment_creation(open_json('bump_minor.json')) }
        .to_not output.to_stderr
    end
    it 'does not have created action (bump patch)' do
      begin
        modified_json_patch = open_json('bump_patch.json')
        modified_json_patch['action'] = 'not_created'
        expect{ GithubPrCommentTrigger.verify_comment_creation(modified_json_patch) }
          .to output('Exiting because comment was not a bump request').to_stderr
      rescue SystemExit => e
        expect(e.status).to eq(0)
      end
    end
    it 'does not have created action (bump patch)' do
      begin
        modified_json_minor = open_json('bump_minor.json')
        modified_json_minor['action'] = 'not_created'
        expect{ GithubPrCommentTrigger.verify_comment_creation(modified_json_minor) }
          .to output('Exiting because comment was not a bump request').to_stderr
      rescue SystemExit => e
        expect(e.status).to eq(0)
      end
    end
    it 'does not have created action (bump patch)' do
      begin
        modified_json_major = open_json('bump_major.json')
        modified_json_major['action'] = 'not_created'
        expect{ GithubPrCommentTrigger.verify_comment_creation(modified_json_major) }
          .to output('Exiting because comment was not a bump request').to_stderr
      rescue SystemExit => e
        expect(e.status).to eq(0)
      end
    end
  end

  context '#verify_valid_request' do
    it 'comments bump major' do
      expect{ GithubPrCommentTrigger.verify_comment_creation(open_json('bump_major.json')) } 
        .to_not output().to_stderr
      GithubPrCommentTrigger.verify_comment_creation(open_json('bump_major.json'))
      puts GithubPrCommentTrigger.level
      expect(GithubPrCommentTrigger.level).to be_eql('major')
      expect(GithubPrCommentTrigger.envs).to be_eql('*')
    end
    it 'comments bump minor' do
      expect{ GithubPrCommentTrigger.verify_comment_creation(open_json('bump_minor.json')) } 
        .to_not output().to_stderr
      expect(GithubPrCommentTrigger.level).to be_eql('minor')
      expect(GithubPrCommentTrigger.envs).to be_eql('*')
    end
    it 'comments bump patch' do
      expect{ GithubPrCommentTrigger.verify_comment_creation(open_json('bump_patch.json')) } 
        .to_not output().to_stderr
      expect(GithubPrCommentTrigger.level).to be_eql('patch')
      expect(GithubPrCommentTrigger.envs).to be_eql('*')
    end
  end
end
