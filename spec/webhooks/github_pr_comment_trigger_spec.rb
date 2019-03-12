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
  let(:sawyer_mock) { double('Sawyer', :merged => false) }
  let(:sawyer_merged_mock) { double('Sawyer', :merged => true) }
  # non_bump_message with newline character to match puts output
  let(:non_bump_message) { "Exiting because comment was not a bump request\n" }

  before :each do
    allow(Octokit::Client).to receive(:new) { github_mock }
    allow(YAML).to receive(:load_file).with('github_pr_comment_trigger.yml')
      .and_return(open_yaml('github_pr_comment_trigger.yml'))
    allow(github_mock).to receive(:pull_request) { sawyer_mock }
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
      expect(GithubPrCommentTrigger.non_bump_message)
        .to eql('Exiting because comment was not a bump request')
      expect(GithubPrCommentTrigger.do_not_upload_cookbooks).to be true
    end
  end

  context '#verify_comment_creation' do
    it 'has created action' do
      expect { GithubPrCommentTrigger.verify_comment_creation(open_json('bump_major.json')) }
        .to_not output.to_stderr
      expect { GithubPrCommentTrigger.verify_comment_creation(open_json('bump_patch.json')) }
        .to_not output.to_stderr
      expect { GithubPrCommentTrigger.verify_comment_creation(open_json('bump_minor.json')) }
        .to_not output.to_stderr
    end
    it 'does not have created action (bump patch)' do
      modified_json = open_json('bump_patch.json')
      modified_json['action'] = 'not_created'
      expect do
        expect { GithubPrCommentTrigger.verify_comment_creation(modified_json) }
          .to raise_error(SystemExit)
      end.to output(non_bump_message).to_stderr
    end
    it 'does not have created action (bump minor)' do
      modified_json = open_json('bump_minor.json')
      modified_json['action'] = 'not_created'
      expect do
        expect { GithubPrCommentTrigger.verify_comment_creation(modified_json) }
          .to raise_error(SystemExit)
      end.to output(non_bump_message).to_stderr
    end
    it 'does not have created action (bump major)' do
      begin
        modified_json = open_json('bump_major.json')
        modified_json['action'] = 'not_created'
        expect do
          expect { GithubPrCommentTrigger.verify_comment_creation(modified_json) }
            .to raise_error(SystemExit)
        end.to output(non_bump_message).to_stderr
      rescue SystemExit => e
        expect(e.status).to eq(0)
      end
    end
  end

  context '#verify_valid_request' do
    it 'comments bump major' do
      expect { GithubPrCommentTrigger.verify_valid_request(open_json('bump_major.json')) } 
        .to_not output().to_stderr
      expect(GithubPrCommentTrigger.level).to eql('major')
      expect(GithubPrCommentTrigger.envs).to eql('*')
    end
    it 'comments bump minor' do
      expect { GithubPrCommentTrigger.verify_valid_request(open_json('bump_minor.json')) } 
        .to_not output().to_stderr
      expect(GithubPrCommentTrigger.level).to eql('minor')
      expect(GithubPrCommentTrigger.envs).to eql('*')
    end
    it 'comments bump patch' do
      expect { GithubPrCommentTrigger.verify_valid_request(open_json('bump_patch.json')) } 
        .to_not output().to_stderr
      expect(GithubPrCommentTrigger.level).to eql('patch')
      expect(GithubPrCommentTrigger.envs).to eql('*')
    end
    it 'does not match comment' do
      begin
        modified_json = open_json('bump_major.json')
        modified_json['comment']['body'] = '!bump  major  *'
        expect { GithubPrCommentTrigger.verify_valid_request(modified_json) }
          .to output(non_bump_message).to_stderr
      rescue SystemExit => e
        expect(e.status).to eq(0)
      end
    end
    it 'does not include env in comment' do
      modified_json = open_json('bump_major.json')
      modified_json['comment']['body'] = '!bump major'
      expect { GithubPrCommentTrigger.verify_valid_request(modified_json) } 
        .to_not output().to_stderr
      expect(GithubPrCommentTrigger.level).to eql('major')
      expect(GithubPrCommentTrigger.envs).to be_nil
    end
  end

  context '#verify_issue_is_pr' do
    it 'is a pr' do
      expect { GithubPrCommentTrigger.verify_issue_is_pr(open_json('bump_major.json')) }
        .to_not output().to_stderr
    end
    it 'is not a pr' do
      begin
        modified_json = open_json('bump_major.json')
        modified_json['issue'].delete('pull_request')
        expect { GithubPrCommentTrigger.verify_issue_is_pr(modified_json) }
          .to output('Error: Cannot merge issue; can only merge PRs.').to_stderr
      rescue SystemExit => e
        expect(e.status).to eq(1)
      end
    end
  end

#  context 'verify_pr_not_merged' do
#    it 'pr is not yet merged' do
#      begin
#        expect { GithubPrCommentTrigger.verify_pr_not_merged(open_json('bump_major.json')) }
#          .to_not output().to_stderr
#        expect(GithubPrCommentTrigger.repo_name).to eql('osl-jenkins')
#        expect(GithubPrCommentTrigger.repo_path).to eql('osuosl-cookbooks/osl-jenkins')
#        expect(GithubPrCommentTrigger.pr).to eq(sawyer_mock)
#      rescue SystemExit => e
#        puts GithubPrCommentTrigger.issue_number
#        expect(GithubPrCommentTrigger.issue_number).to eq(143)
#        #puts sawyer_mock.merged
#        #puts GithubPrCommentTrigger.pr.merged
#        puts e.status
#      end
#    end
#    it 'pr is already merged' do
#      begin
#        allow('github_mock').to receive(:pull_request) { sawyer_merged_mock }
#        expect { GithubPrCommentTrigger.verify_pr_not_merged(open_json('bump_major.json')) }
#          .to output('Error: Cannot merge PR because it has already been merged.').to_stderr
#      rescue SystemExit => e
#        expect(e.status).to eq(1)
#      end
#    end
#  end
#
#  context 'verify_pr_mergeable' do
#    it 'pr is mergeable' do
#      expect { GithubPrCommentTrigger.verify_pr_mergeable(open_json('bump_major.json')) }
#        .to_not output().to_stderr
#    end
#    it 'pr is not mergeable' do
#
#    end
#  end
end
