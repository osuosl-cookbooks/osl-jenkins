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

  def modify_node_attr(orig_attr, modified_attr)
    modified_attr.each do |key, val|
      orig_attr[key] = val
    end
    return orig_attr
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
  let(:sawyer_mock) { double('Sawyer', :merged => false, :mergeable => true) }
  let(:sawyer_merged_mock) { double('Sawyer', :merged => true, :mergeable => true) }
  let(:sawyer_unmergeable_mock) { double('Sawyer', :merged => false, :mergeable => false) }
  let(:head_ref_mock) { double('Sawyer', :ref => 'eldebrim/chef13') }
  let(:major_pr_mock) { double(
    'Sawyer', :merged => false, :mergeable => true,
    :head => head_ref_mock
  )}
  let(:sawyer_teams_mock) {[
    double('Sawyer', :name => 'staff', :id => 1),
    double('Sawyer', :name => 'chefs', :id => 2)
  ]}
  # non_bump_message with newline character to match puts output
  let(:non_bump_message) { "Exiting because comment was not a bump request\n" }

  before :each do
    allow(Octokit::Client).to receive(:new) { github_mock }
    allow(YAML).to receive(:load_file).with('github_pr_comment_trigger.yml')
      .and_return(open_yaml('github_pr_comment_trigger.yml'))
    allow(github_mock).to receive(:pull_request) { major_pr_mock }
    allow(github_mock).to receive(:organization_teams).with('osuosl-cookbooks').and_return(sawyer_teams_mock)
    allow(github_mock).to receive(:team_membership).with(1, 'eldebrim').and_return(sawyer_mock)
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

  context '#setup_github' do
    it 'ensure Octokit::Client creates github_mock' do
      GithubPrCommentTrigger.setup_github
      expect(GithubPrCommentTrigger.github).to eq(github_mock)
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
      modified_json = open_json('bump_major.json')
      modified_json['action'] = 'not_created'
      expect do
        expect { GithubPrCommentTrigger.verify_comment_creation(modified_json) }
          .to raise_error(SystemExit)
      end.to output(non_bump_message).to_stderr
    end
  end

  context '#verify_valid_request' do
    it 'comments bump major' do
      expect { GithubPrCommentTrigger.verify_valid_request(open_json('bump_major.json')) } 
        .to_not output.to_stderr
      expect(GithubPrCommentTrigger.level).to eql('major')
      expect(GithubPrCommentTrigger.envs).to eql('*')
    end
    it 'comments bump minor' do
      expect { GithubPrCommentTrigger.verify_valid_request(open_json('bump_minor.json')) } 
        .to_not output.to_stderr
      expect(GithubPrCommentTrigger.level).to eql('minor')
      expect(GithubPrCommentTrigger.envs).to eql('*')
    end
    it 'comments bump patch' do
      expect { GithubPrCommentTrigger.verify_valid_request(open_json('bump_patch.json')) } 
        .to_not output.to_stderr
      expect(GithubPrCommentTrigger.level).to eql('patch')
      expect(GithubPrCommentTrigger.envs).to eql('*')
    end
    it 'does not match comment' do
      modified_json = open_json('bump_major.json')
      modified_json['comment']['body'] = '!bump  major  *'
      expect do
        expect { GithubPrCommentTrigger.verify_valid_request(modified_json) }
          .to raise_error(SystemExit)
      end.to output(non_bump_message).to_stderr
    end
    it 'does not include env in comment' do
      modified_json = open_json('bump_major.json')
      modified_json['comment']['body'] = '!bump major'
      expect { GithubPrCommentTrigger.verify_valid_request(modified_json) } 
        .to_not output.to_stderr
      expect(GithubPrCommentTrigger.level).to eql('major')
      expect(GithubPrCommentTrigger.envs).to be_nil
    end
  end

  context '#verify_issue_is_pr' do
    it 'is a pr' do
      expect { GithubPrCommentTrigger.verify_issue_is_pr(open_json('bump_major.json')) }
        .to_not output.to_stderr
    end
    it 'is not a pr' do
      modified_json = open_json('bump_major.json')
      modified_json['issue'].delete('pull_request')
      expect do
        expect { GithubPrCommentTrigger.verify_issue_is_pr(modified_json) }
          .to raise_error(SystemExit)
      end.to output("Error: Cannot merge issue; can only merge PRs.\n").to_stderr
    end
  end

  context 'verify_pr_not_merged' do
    it 'pr is not yet merged' do
      GithubPrCommentTrigger.setup_github
      expect do
        GithubPrCommentTrigger.verify_pr_not_merged(open_json('bump_major.json'))
      end.to_not output.to_stderr
      expect(GithubPrCommentTrigger.repo_name).to eql('osl-jenkins')
      expect(GithubPrCommentTrigger.repo_path).to eql('osuosl-cookbooks/osl-jenkins')
      expect(GithubPrCommentTrigger.issue_number).to eql(143)
      expect(GithubPrCommentTrigger.pr).to eq(major_pr_mock)
    end
    it 'pr is already merged' do
      allow(github_mock).to receive(:pull_request) { sawyer_merged_mock }
      GithubPrCommentTrigger.setup_github
      expect do
        expect { GithubPrCommentTrigger.verify_pr_not_merged(open_json('bump_major.json')) }
          .to raise_error(SystemExit)
      end.to output("Error: Cannot merge PR because it has already been merged.\n").to_stderr
    end
  end

  context 'verify_pr_mergeable' do
    it 'pr is mergeable' do
      json = open_json('bump_major.json')
      GithubPrCommentTrigger.setup_github
      GithubPrCommentTrigger.verify_pr_not_merged(json)
      expect { GithubPrCommentTrigger.verify_pr_mergeable(json) }
        .to_not output.to_stderr
    end
    it 'pr is not mergeable' do
      allow(github_mock).to receive(:pull_request) { sawyer_unmergeable_mock }
      json = open_json('bump_major.json')
      GithubPrCommentTrigger.setup_github
      GithubPrCommentTrigger.verify_pr_not_merged(json)
      expect do
        expect { GithubPrCommentTrigger.verify_pr_mergeable(json) }
          .to raise_error(SystemExit)
      end.to output("Error: Cannot merge PR because it would create merge conflicts.\n").to_stderr
    end
  end

  context '#team_member?' do
    it 'finds user in team' do
      GithubPrCommentTrigger.setup_github
      expect(GithubPrCommentTrigger.team_member?('osuosl-cookbooks/staff', 'eldebrim'))
        .to eq(sawyer_mock)
    end
    it 'does not find user in team' do
      allow(github_mock).to receive(:team_membership).with(1, 'eldebrim').and_raise(Octokit::NotFound)
      GithubPrCommentTrigger.setup_github
      expect(GithubPrCommentTrigger.team_member?('osuosl-cookbooks/staff', 'eldebrim'))
        .to be false
    end
# Is it safe to assume team always in org?
    it 'does not find team in org' do
      GithubPrCommentTrigger.setup_github
      expect { GithubPrCommentTrigger.team_member?('osuosl-cookbooks/not_team', 'eldebrim') }
        .to raise_error(NoMethodError)
    end
  end

  context '#verify_commenter_permission' do
    it 'passes when authorized_user/orgs/teams are all empty' do
      modified_attr = { 'authorized_teams' => [] }
      json = open_json('bump_major.json')
      allow(YAML).to receive(:load_file).and_call_original
      allow(YAML).to receive(:load_file).with('github_pr_comment_trigger.yml')
        .and_return(modify_node_attr(open_yaml('github_pr_comment_trigger.yml'), modified_attr))
      GithubPrCommentTrigger.load_node_attr
      GithubPrCommentTrigger.setup_github
      expect { GithubPrCommentTrigger.verify_commenter_permission(json) }
        .to_not output.to_stderr
    end
    it 'passes when user is in authorized_users' do
      modified_attr = {
        'authrized_users' => ['eldebrim'],
        'authorized_teams' => []
      }
      json = open_json('bump_major.json')
      allow(YAML).to receive(:load_file).and_call_original
      allow(YAML).to receive(:load_file).with('github_pr_comment_trigger.yml')
        .and_return(modify_node_attr(open_yaml('github_pr_comment_trigger.yml'), modified_attr))
      GithubPrCommentTrigger.load_node_attr
      GithubPrCommentTrigger.setup_github
      expect { GithubPrCommentTrigger.verify_commenter_permission(json) }
        .to_not output.to_stderr
    end
    it 'passes when one of user\'s org is in authorized_orgs' do
      modified_attr = {
        'authrized_users' => [],
        'authorized_orgs' => ['test_org'],
        'authorized_teams' => []
      }
      json = open_json('bump_major.json')
      allow(YAML).to receive(:load_file).and_call_original
      allow(YAML).to receive(:load_file).with('github_pr_comment_trigger.yml')
        .and_return(modify_node_attr(open_yaml('github_pr_comment_trigger.yml'), modified_attr))
      allow(github_mock).to receive(:organization_member?).with('test_org', 'eldebrim').and_return(true)
      GithubPrCommentTrigger.load_node_attr
      GithubPrCommentTrigger.setup_github
      expect { GithubPrCommentTrigger.verify_commenter_permission(json) }
        .to_not output.to_stderr
    end
    it 'passes when one of user\'s team is in authorized_teams' do
      json = open_json('bump_major.json')
      GithubPrCommentTrigger.load_node_attr
      GithubPrCommentTrigger.setup_github
      expect { GithubPrCommentTrigger.verify_commenter_permission(json) }
        .to_not output.to_stderr
    end
    it 'aborts when none of above conditions are met' do
      modified_attr = {
        'authrized_users' => ['not_user'],
        'authorized_orgs' => ['not_org'],
        'authorized_teams' => ['osuosl-cookbooks/staff']
      }
      json = open_json('bump_major.json')
      allow(YAML).to receive(:load_file).and_call_original
      allow(YAML).to receive(:load_file).with('github_pr_comment_trigger.yml')
        .and_return(modify_node_attr(open_yaml('github_pr_comment_trigger.yml'), modified_attr))
      allow(github_mock).to receive(:organization_member?).with('not_org', 'eldebrim').and_return(false)
      allow(github_mock).to receive(:team_membership).with(1, 'eldebrim').and_raise(Octokit::NotFound)
      GithubPrCommentTrigger.load_node_attr
      GithubPrCommentTrigger.setup_github
      expect do
        expect { GithubPrCommentTrigger.verify_commenter_permission(json) }
          .to raise_error(SystemExit)
      end.to output("Error: Cannot merge PR because user 'eldebrim' is not authorized.\n").to_stderr
    end
  end
  context '#verify' do
    it 'verifies without error, calls other verify functions' do
      allow(STDIN).to receive(:read).and_return(open_fixture('bump_major.json'))
      expect(GithubPrCommentTrigger).to receive(:verify_comment_creation)
      expect(GithubPrCommentTrigger).to receive(:verify_valid_request)
      expect(GithubPrCommentTrigger).to receive(:verify_issue_is_pr)
      expect(GithubPrCommentTrigger).to receive(:verify_pr_not_merged)
      expect(GithubPrCommentTrigger).to receive(:verify_pr_mergeable)
      expect(GithubPrCommentTrigger).to receive(:verify_commenter_permission)
      expect { GithubPrCommentTrigger.verify }.to_not output.to_stderr
    end
  end
  context '#merge_pr' do
    it 'merges_pr' do
      allow(STDIN).to receive(:read).and_return(open_fixture('bump_major.json'))
      allow(github_mock).to receive(:merge_pull_request).with('osuosl-cookbooks/osl-jenkins', 143)
      allow(github_mock).to receive(:delete_branch).with('osuosl-cookbooks/osl-jenkins', 'eldebrim/chef13')
      GithubPrCommentTrigger.load_node_attr
      GithubPrCommentTrigger.setup_github
      GithubPrCommentTrigger.verify
      expect { GithubPrCommentTrigger.merge_pr }.to_not raise_error
    end
  end
end
