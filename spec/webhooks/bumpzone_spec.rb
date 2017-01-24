require 'rspec'
require 'rspec/mocks'
require 'tempfile'
require 'pathname'
require_relative '../../files/default/lib/bumpzone'

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

describe BumpZone do
  it '@commit_msg' do
    expect(BumpZone.commit_msg).to eq "\n\n"
  end
  context '#add_commit_msg' do
    it 'adds commit message' do
      BumpZone.add_commit_msg('foo')
      expect(BumpZone.commit_msg).to match(/foo/)
    end
  end
  context '#regex' do
    it 'matching regex' do
      expect(BumpZone.regex('foo', /foo/)).to eq true
    end
    it 'non-matching regex' do
      expect(BumpZone.regex('foo', /bar/)).to eq false
    end
  end
  context '#pr_merged' do
    it 'merged' do
      expect(BumpZone.pr_merged(open_json('merge_payload.json'))).to eq nil
    end
    it 'not merged' do
      begin
        expect(BumpZone.pr_merged(open_json('open_pr_payload.json'))).to_not eq nil
        expect(BumpZone.pr_merged(
                 open_json('open_pr_payload.json')
        )).to output('Not a merged PR, skipping...').to_stdout
      rescue SystemExit => e
        expect(e.status).to eq 0
      end
    end
  end
  context '#changed_files' do
    let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false) }
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
    end
    it 'finds single changed file' do
      response_body = [double('Sawyer::Resource', filename: 'db.osuosl.org')]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/zonefiles-test', 1).and_return(response_body)
      files = BumpZone.changed_files(open_json('merge_payload.json'))
      expect(files.first.filename).to match(/db.osuosl.org/)
    end
    it 'finds multiple changed files' do
      response_body = [
        double('Sawyer::Resource', filename: 'db.osuosl.org'),
        double('Sawyer::Resource', filename: 'db.bak')
      ]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/zonefiles-test', 1).and_return(response_body)
      files = BumpZone.changed_files(open_json('merge_payload.json'))
      expect(files[0].filename).to match(/db.osuosl.org/)
      expect(files[1].filename).to match(/db.bak/)
    end
  end
  context '#git_push' do
    let(:git_mock) { double('Git::Base') }
    before :each do
      allow(git_mock).to receive :add
      allow(git_mock).to receive :commit
      allow(git_mock).to receive :push
      allow(git_mock).to receive :remote
      allow(Git).to receive(:open).and_return git_mock
    end
    it 'Opens git dir' do
      expect(Git).to receive(:open).with('.').and_return git_mock
      BumpZone.git_push
    end
    it 'Adds all files' do
      expect(git_mock).to receive(:add).with(all: true)
      BumpZone.git_push
    end
    it 'Commits the files' do
      expect(git_mock).to receive(:commit).with(/Automatically bumping zone serials\n\nfoo/)
      BumpZone.git_push
    end
    it 'Pushes commits to origin master' do
      expect(git_mock).to receive(:push).with(git_mock.remote('origin'), 'master')
      BumpZone.git_push
    end
  end
  context '#soa_oneline?' do
    it 'One line SOA' do
      expect(BumpZone.soa_oneline?(open_fixture('oneline-soa'))).to eq true
    end
    it 'Multiline SOA' do
      expect(BumpZone.soa_oneline?(open_fixture('multiline-soa'))).to eq false
    end
    it 'No SOA found' do
      expect(BumpZone.soa_oneline?(open_fixture('no-soa'))).to eq false
    end
  end
  context '#print_soa' do
    it 'prints soa' do
      expect(BumpZone.print_soa('before', 'serial', 'after')).to eq 'beforeserialafter'
    end
  end
  context '#counter?' do
    it do
      expect(BumpZone.counter?(00)).to eq false
    end
    it do
      expect(BumpZone.counter?(99)).to eq true
    end
  end
  context '#new_serial' do
    it 'oneline soa' do
      expect(BumpZone.new_serial(
               open_fixture('oneline-soa'), 'db.osuosl.org'
      )).to eq Time.new.strftime('%Y%m%d00').to_i
    end
    it 'multiline soa' do
      expect(BumpZone.new_serial(
               open_fixture('multiline-soa'), 'db.osuosl.org'
      )).to eq Time.new.strftime('%Y%m%d00').to_i
    end
    it 'increment oneline soa' do
      soa = 'osuosl.org.     86400   IN  SOA ns1.auth.osuosl.org. hostmaster.osuosl.org. ' \
            "#{Time.new.strftime('%Y%m%d00').to_i} 3600 900 604800 86400"
      expect(BumpZone.new_serial(soa, 'db.osuosl.org')).to eq Time.new.strftime('%Y%m%d01').to_i
    end
    it 'increment multiline soa' do
      soa = <<EOF
osuosl.org      IN SOA  ns1.auth.osuosl.org. hostmaster.osuosl.org. (
                #{Time.new.strftime('%Y%m%d00').to_i} ; serial
                3600       ; refresh (1 hour)
                900        ; retry (15 minutes)
                604800     ; expire (1 week)
                86400      ; minimum (1 day)
                )
EOF
      expect(BumpZone.new_serial(soa, 'db.osuosl.org')).to eq Time.new.strftime('%Y%m%d01').to_i
    end
    it 'fails to find an soa' do
      expect(BumpZone.new_serial(open_fixture('no-soa'), 'db.osuosl.org')).to eq nil
    end
    it 'counter is at 99' do
      soa = 'osuosl.org.     86400   IN  SOA ns1.auth.osuosl.org. hostmaster.osuosl.org. ' \
            "#{Time.new.strftime('%Y%m%d99').to_i} 3600 900 604800 86400"
      expect(BumpZone.new_serial(soa, 'db.osuosl.org')).to eq nil
    end
    it 'Bump commit message' do
      BumpZone.new_serial(open_fixture('oneline-soa'), 'db.osuosl.org')
      expect(BumpZone.commit_msg).to \
        match(/Bump db.osuosl.org from 1484352036 to #{Time.new.strftime('%Y%m%d00').to_i}/)
    end
  end
  context '#bump' do
    it 'Bump oneline soa' do
      oneline = tempfile(fixture_path('oneline-soa'))
      BumpZone.bump(oneline.path)
      oneline.rewind
      expect(oneline.read).to match(/#{Time.new.strftime('%Y%m%d00').to_i}/)
    end
    it 'Bump multiline soa' do
      multiline = tempfile(fixture_path('multiline-soa'))
      BumpZone.bump(multiline.path)
      multiline.rewind
      expect(multiline.read).to match(/#{Time.new.strftime('%Y%m%d00').to_i}/)
    end
    it 'No soa' do
      nosoa = tempfile(fixture_path('no-soa'))
      BumpZone.bump(nosoa.path)
      nosoa.rewind
      expect(nosoa.read).to_not match(/#{Time.new.strftime('%Y%m%d00').to_i}/)
    end
  end
  context '#start' do
    let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false) }
    let(:git_mock) { double('Git::Base') }
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
      allow(git_mock).to receive :add
      allow(git_mock).to receive :commit
      allow(git_mock).to receive :push
      allow(git_mock).to receive :remote
      allow(Git).to receive(:open).and_return git_mock
    end
    it 'completes a whole bump operation with oneline soa' do
      file = tempfile(fixture_path('db.osuosl.org'))
      response_body = [double('Sawyer::Resource', filename: file)]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/zonefiles-test', 1).and_return(response_body)
      allow(STDIN).to receive(:read).and_return(open_fixture('merge_payload.json'))
      BumpZone.start
      file.rewind
      expect(file.read).to match(/#{Time.new.strftime('%Y%m%d00').to_i}/)
    end
    it 'completes a whole bump operation with multiline soa' do
      file = tempfile(fixture_path('db.osuosl.net'))
      response_body = [double('Sawyer::Resource', filename: file)]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/zonefiles-test', 1).and_return(response_body)
      allow(STDIN).to receive(:read).and_return(open_fixture('merge_payload.json'))
      BumpZone.start
      file.rewind
      expect(file.read).to match(/#{Time.new.strftime('%Y%m%d00').to_i}/)
    end
    it 'Skips file not named properly' do
      file = tempfile(fixture_path('oneline-soa'))
      response_body = [double('Sawyer::Resource', filename: file)]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/zonefiles-test', 1).and_return(response_body)
      allow(STDIN).to receive(:read).and_return(open_fixture('merge_payload.json'))
      BumpZone.start
      file.rewind
      expect(file.read).to_not match(/#{Time.new.strftime('%Y%m%d00').to_i}/)
    end
  end
end
