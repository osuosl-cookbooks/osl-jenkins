require 'rspec'
require 'rspec/mocks'
require 'tempfile'
require 'pathname'
require_relative '../../files/default/lib/checkzone'

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

describe CheckZone do
  let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }
  context '#reset' do
    it 'resets variables' do
      CheckZone.add_issue_msg('not here')
      expect(CheckZone.issue_msg).to match(/not here/)
      CheckZone.reset
      expect(CheckZone.issue_msg).to_not match(/not here/)
    end
  end
  context '#add_issue_msg' do
    it 'adds issue message' do
      CheckZone.add_issue_msg("foo\n")
      expect(CheckZone.issue_msg).to match(/foo\n/)
    end
  end
  context '#github_init' do
    it 'initializes github client' do
      CheckZone.reset
      CheckZone.github_init(open_json('open_pr_payload.json'))
      expect(CheckZone.repo_path).to match(%r{^osuosl/zonefiles-test$})
      expect(CheckZone.issue_number).to match(1)
    end
  end
  context '#commit_status' do
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
      ENV['BUILD_URL'] = 'http://jenkins.osuosl.org/job/checkzone/1/'
      ENV['GIT_COMMIT'] = 'sha1'
    end
    it 'sets success commit_status' do
      allow(github_mock).to receive(:create_status)
        .with(
          'osuosl/zonefiles-test',
          'sha1',
          'success',
          context: 'checkzone',
          target_url: 'http://jenkins.osuosl.org/job/checkzone/1/console',
          description: 'named-checkzone has passed'
        )
      expect(github_mock).to receive(:create_status)
        .with(
          'osuosl/zonefiles-test',
          'sha1',
          'success',
          context: 'checkzone',
          target_url: 'http://jenkins.osuosl.org/job/checkzone/1/console',
          description: 'named-checkzone has passed'
        )
      CheckZone.reset
      CheckZone.github_init(open_json('open_pr_payload.json'))
      CheckZone.commit_status('success')
    end
    it 'sets failure commit_status' do
      allow(github_mock).to receive(:create_status)
        .with(
          'osuosl/zonefiles-test',
          'sha1',
          'failure',
          context: 'checkzone',
          target_url: 'http://jenkins.osuosl.org/job/checkzone/1/console',
          description: 'named-checkzone has found a syntax error'
        )
      expect(github_mock).to receive(:create_status)
        .with(
          'osuosl/zonefiles-test',
          'sha1',
          'failure',
          context: 'checkzone',
          target_url: 'http://jenkins.osuosl.org/job/checkzone/1/console',
          description: 'named-checkzone has found a syntax error'
        )
      CheckZone.reset
      CheckZone.github_init(open_json('open_pr_payload.json'))
      CheckZone.commit_status('failure')
    end
    it 'no git commit sha1' do
      ENV['GIT_COMMIT'] = nil
      expect(github_mock).to_not receive(:create_status)
      CheckZone.reset
      CheckZone.github_init(open_json('open_pr_payload.json'))
      CheckZone.commit_status('failure')
    end
  end
  context '#changed_files' do
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
    end
    it 'finds single changed file' do
      response_body = [double('Sawyer::Resource', filename: 'db.osuosl.org')]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/zonefiles-test', 1).and_return(response_body)
      CheckZone.reset
      CheckZone.github_init(open_json('open_pr_payload.json'))
      files = CheckZone.changed_files
      expect(files.first.filename).to match(/db.osuosl.org/)
    end
    it 'finds multiple changed files' do
      response_body = [
        double('Sawyer::Resource', filename: 'db.osuosl.org'),
        double('Sawyer::Resource', filename: 'db.osuosl.com')
      ]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/zonefiles-test', 10).and_return(response_body)
      CheckZone.reset
      CheckZone.github_init(open_json('sync_multifile_payload.json'))
      files = CheckZone.changed_files
      expect(files[0].filename).to match(/db.osuosl.org/)
      expect(files[1].filename).to match(/db.osuosl.com/)
    end
  end
  context '#checkzone' do
    it 'named-checkzone pass' do
      zone_file = double('Sawyer::Resource', filename: fixture_path('db.osuosl.com'))
      allow(Open3).to receive(:popen2)
        .with('/usr/sbin/named-checkzone osuosl.com ' + fixture_path('db.osuosl.com'))
        .and_return([
                      nil,
                      StringIO.new('pass'),
                      double(value: double(Process::Status, exitstatus: 0))
                    ])
      CheckZone.reset
      CheckZone.checkzone(zone_file)
      expect(CheckZone.syntax_error).to match false
      expect(CheckZone.issue_msg).to_not match(/pass/)
    end
    it 'named-checkzone fail' do
      zone_file = double('Sawyer::Resource', filename: fixture_path('db.osuosl.org'))
      allow(Open3).to receive(:popen2)
        .with('/usr/sbin/named-checkzone osuosl.org ' + fixture_path('db.osuosl.org'))
        .and_return([
                      nil,
                      StringIO.new(open_fixture('named-checkzone')),
                      double(value: double(Process::Status, exitstatus: 1))
                    ])
      CheckZone.reset
      CheckZone.checkzone(zone_file)
      expect(CheckZone.syntax_error).to match true
      expect(CheckZone.issue_msg).to match(open_fixture('named-checkzone'))
    end
  end
  context '#post_msg' do
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
      ENV['BUILD_URL'] = 'http://jenkins.osuosl.org/job/checkzone/1/'
      ENV['GIT_COMMIT'] = 'sha1'
    end
    it 'posts a comment to github' do
      allow(github_mock).to receive(:create_status)
        .with(
          'osuosl/zonefiles-test',
          'sha1',
          'failure',
          context: 'checkzone',
          target_url: 'http://jenkins.osuosl.org/job/checkzone/1/console',
          description: 'named-checkzone has found a syntax error'
        )
      allow(github_mock).to receive(:add_comment)
        .with(
          'osuosl/zonefiles-test',
          10,
          "Zone syntax error(s) found:\n\n```\n```\n"
        )
      begin
        expect(github_mock).to receive(:create_status)
          .with(
            'osuosl/zonefiles-test',
            'sha1',
            'failure',
            context: 'checkzone',
            target_url: 'http://jenkins.osuosl.org/job/checkzone/1/console',
            description: 'named-checkzone has found a syntax error'
          )
        CheckZone.reset
        CheckZone.github_init(open_json('sync_multifile_payload.json'))
        CheckZone.post_msg
      rescue SystemExit => e
        expect(e.status).to eq 1
        expect(CheckZone.issue_msg).to match(/Zone syntax error\(s\) found:\n\n```\n```\n/)
      end
    end
  end
  context '#pr_updated' do
    before do
      allow(STDOUT).to receive(:puts)
    end
    it 'synchronize PR' do
      begin
        CheckZone.reset
        CheckZone.pr_updated(open_json('sync_payload.json'))
      rescue SystemExit => e
        expect(e.status).to_not eq 0
      end
    end
    it 'open PR' do
      begin
        CheckZone.reset
        CheckZone.pr_updated(open_json('open_pr_payload.json'))
      rescue SystemExit => e
        expect(e.status).to_not eq 0
      end
    end
    it 'closed PR' do
      begin
        expect(STDOUT).to receive(:puts).with('Not an updated or created PR, skipping...')
        CheckZone.reset
        CheckZone.pr_updated(open_json('merge_payload.json'))
      rescue SystemExit => e
        expect(e.status).to eq 0
      end
    end
  end
  context '#start' do
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
      allow(STDOUT).to receive(:puts)
      ENV['BUILD_URL'] = 'http://jenkins.osuosl.org/job/checkzone/1/'
      ENV['GIT_COMMIT'] = 'sha1'
    end
    it 'checks a zone that passes' do
      response_body = [double('Sawyer::Resource', filename: 'db.osuosl.org')]
      allow(github_mock).to receive(:create_status)
        .with(
          'osuosl/zonefiles-test',
          'sha1',
          'success',
          context: 'checkzone',
          target_url: 'http://jenkins.osuosl.org/job/checkzone/1/console',
          description: 'named-checkzone has passed'
        )
      allow(Open3).to receive(:popen2)
        .with('/usr/sbin/named-checkzone osuosl.org db.osuosl.org')
        .and_return([
                      nil,
                      StringIO.new('pass'),
                      double(value: double(Process::Status, exitstatus: 0))
                    ])
      allow(github_mock).to receive(:pull_request_files).with('osuosl/zonefiles-test', 1).and_return(response_body)
      allow(github_mock).to receive(:add_comment)
        .with(
          'osuosl/zonefiles-test',
          1,
          "Zone syntax error(s) found:\n\n"
        )
      allow(STDIN).to receive(:read).and_return(open_fixture('open_pr_payload.json'))
      begin
        expect(github_mock).to receive(:create_status)
          .with(
            'osuosl/zonefiles-test',
            'sha1',
            'success',
            context: 'checkzone',
            target_url: 'http://jenkins.osuosl.org/job/checkzone/1/console',
            description: 'named-checkzone has passed'
          )
        CheckZone.reset
        CheckZone.start
        expect(CheckZone.syntax_error).to eq false
        expect(CheckZone.issue_msg).to match(/^Zone syntax error\(s\) found:\n\n```$/)
      rescue SystemExit => e
        expect(e.status).to eq 0
      end
    end
    it 'checks a zone that fails' do
      response_body = [double('Sawyer::Resource', filename: 'db.osuosl.org')]
      allow(github_mock).to receive(:create_status)
        .with(
          'osuosl/zonefiles-test',
          'sha1',
          'failure',
          context: 'checkzone',
          target_url: 'http://jenkins.osuosl.org/job/checkzone/1/console',
          description: 'named-checkzone has found a syntax error'
        )
      allow(Open3).to receive(:popen2)
        .with('/usr/sbin/named-checkzone osuosl.org db.osuosl.org')
        .and_return([
                      nil,
                      StringIO.new("failed\n"),
                      double(value: double(Process::Status, exitstatus: 1))
                    ])
      allow(github_mock).to receive(:pull_request_files).with('osuosl/zonefiles-test', 1).and_return(response_body)
      allow(github_mock).to receive(:add_comment)
        .with(
          'osuosl/zonefiles-test',
          1,
          "Zone syntax error(s) found:\n\n```\nfailed\n```\n"
        )
      allow(STDIN).to receive(:read).and_return(open_fixture('open_pr_payload.json'))
      begin
        expect(github_mock).to receive(:create_status)
          .with(
            'osuosl/zonefiles-test',
            'sha1',
            'failure',
            context: 'checkzone',
            target_url: 'http://jenkins.osuosl.org/job/checkzone/1/console',
            description: 'named-checkzone has found a syntax error'
          )
        CheckZone.reset
        CheckZone.start
      rescue SystemExit => e
        expect(e.status).to eq 1
        expect(CheckZone.syntax_error).to eq true
        expect(CheckZone.issue_msg).to match(/Zone syntax error\(s\) found:\n\n```\nfailed\n```\n/)
      end
    end
    it 'merged PR passes through' do
      allow(STDIN).to receive(:read).and_return(open_fixture('merge_payload.json'))
      begin
        CheckZone.reset
        expect(STDOUT).to receive(:puts).with('Not an updated or created PR, skipping...')
        CheckZone.start
      rescue SystemExit => e
        expect(e.status).to eq 0
        expect(CheckZone.syntax_error).to eq false
        expect(CheckZone.issue_msg).to match(/Zone syntax error\(s\) found:\n\n```/)
      end
    end
  end
end
