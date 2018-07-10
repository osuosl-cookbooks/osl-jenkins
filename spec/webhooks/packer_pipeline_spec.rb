require 'rspec'
require 'rspec/mocks'
require 'tempfile'
require 'pathname'
require_relative '../../files/default/lib/packer_pipeline'

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

describe PackerPipeline do
  context '#changed_files' do
    let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
    end
    it 'finds single changed file' do
      response_body = [double('Sawyer::Resource', filename: 'centos-7.3-x86_64-openstack.json')]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      files = PackerPipeline.new.changed_files(open_json('sync_packer_templates.json'))
      expect(files.first.filename).to match(/centos-7.3-x86_64-openstack.json/)
    end
    it 'finds single changed file w/ issue payload' do
      response_body = [double('Sawyer::Resource', filename: 'centos-7.3-x86_64-openstack.json')]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 59).and_return(response_body)
      files = PackerPipeline.new.changed_files(open_json('issue_packer_templates.json'))
      expect(files.first.filename).to match(/centos-7.3-x86_64-openstack.json/)
    end
    it 'finds multiple changed files' do
      response_body = [
        double('Sawyer::Resource', filename: 'centos-7.3-x86_64-openstack.json'),
        double('Sawyer::Resource', filename: 'centos-7.2-ppc64-openstack.json'),
      ]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      files = PackerPipeline.new.changed_files(open_json('sync_packer_templates.json'))
      expect(files[0].filename).to match(/centos-7.3-x86_64-openstack.json/)
      expect(files[1].filename).to match(/centos-7.2-ppc64-openstack.json/)
    end
    it 'finds multiple changed files w/ issue payload' do
      response_body = [
        double('Sawyer::Resource', filename: 'centos-7.3-x86_64-openstack.json'),
        double('Sawyer::Resource', filename: 'centos-7.2-ppc64-openstack.json'),
      ]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 59).and_return(response_body)
      files = PackerPipeline.new.changed_files(open_json('issue_packer_templates.json'))
      expect(files[0].filename).to match(/centos-7.3-x86_64-openstack.json/)
      expect(files[1].filename).to match(/centos-7.2-ppc64-openstack.json/)
    end
  end
  context '#get_commit' do
    let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
    end
    it 'returns a git commit sha' do
      contents_response = {
        head: double('Sawyer::Resource', sha: 'git-sha'),
      }
      response_body = double('Sawyer::Resource', contents_response)
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 59).and_return(response_body)
      commit = PackerPipeline.new.get_commit(59)
      expect(commit).to match(/git-sha/)
    end
  end
  context '#get_status' do
    let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
    end
    it 'returns a git commit combined status' do
      pr_contents_response = { head: double('Sawyer::Resource', sha: 'git-sha') }
      pr_response_body = double('Sawyer::Resource', pr_contents_response)
      contents_response = { state: 'success' }
      response_body = double('Sawyer::Resource', contents_response)
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 59).and_return(pr_response_body)
      allow(github_mock).to receive(:combined_status)
        .with('osuosl/packer-templates', 'git-sha').and_return(response_body)
      commit = PackerPipeline.new.get_status(59)
      expect(commit).to match(/success/)
    end
  end
  context '#abort_comment' do
    let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
    end
    it 'adds comment and aborts' do
      allow(github_mock).to receive(:add_comment).with('osuosl/packer-templates', 59, 'error comment')
      begin
        expect(STDOUT).to receive(:puts).with('error comment')
        PackerPipeline.new.abort_comment('error comment', 59)
        expect(github_mock).to receive(:add_comment).with('osuosl/packer-templates', 59, 'error comment')
      rescue SystemExit => e
        expect(e.status).to eq 1
      end
    end
  end
  context '#find_dependent_templates' do
    before :each do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('PACKER_TEMPLATES_DIR').and_return(fixture_path(''))
    end
    it 'returns just the template name when a template name is passed' do
      file = fixture_path('centos-7.2-ppc64-openstack.json')
      expect(PackerPipeline.new.find_dependent_templates(file)).to match_array(['centos-7.2-ppc64-openstack.json'])
    end
    it 'returns a single template that uses a script' do
      file = 'scripts/centos/osuosl.sh'
      expect(PackerPipeline.new.find_dependent_templates(file)).to match_array(['centos-7.3-x86_64-openstack.json'])
    end
    it 'returns multiple templates that use a script' do
      file = 'scripts/centos/openstack.sh'
      expect(PackerPipeline.new.find_dependent_templates(file)).to match_array(
        ['centos-7.3-x86_64-openstack.json', 'centos-7.2-ppc64-openstack.json']
      )
    end
    it 'returns nothing when a script is not used by any template' do
      file = fixture_path('this_script_does_not_exist_in_this_universe.sh')
      expect(PackerPipeline.new.find_dependent_templates(file)).to match_array(nil)
    end
  end

  context '#process_payload' do
    let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('PACKER_TEMPLATES_DIR').and_return(fixture_path(''))
    end
    it 'prints the PR number' do
      file = fixture_path('scripts/centos/osuosl.sh')
      response_body = [double('Sawyer::Resource', filename: file)]
      head_response = { sha: 'git-sha' }
      contents_response = { head: double('Sawyer::Resource', head_response) }
      pr_response_body = double('Sawyer::Resource', contents_response)
      commit_response_body = double('Sawyer::Resource', state: 'success')
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 16).and_return(pr_response_body)
      allow(github_mock).to receive(:combined_status)
        .with('osuosl/packer-templates', 'git-sha').and_return(commit_response_body)
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      payload = open_fixture('sync_packer_templates.json')
      expect { puts PackerPipeline.new.process_payload(payload).to_json }.to output(/"pr":16/).to_stdout
      expect do
        puts PackerPipeline.new.process_payload(payload).to_json
      end.to output(/"event_type":"pull_request"/).to_stdout
      expect { puts PackerPipeline.new.process_payload(payload).to_json }.to output(/"pr_state":"success"/).to_stdout
    end
    it 'prints the PR number w/ issue payload' do
      file = fixture_path('scripts/centos/osuosl.sh')
      response_body = [double('Sawyer::Resource', filename: file)]
      head_response = { sha: 'git-sha' }
      contents_response = { head: double('Sawyer::Resource', head_response) }
      pr_response_body = double('Sawyer::Resource', contents_response)
      commit_response_body = double('Sawyer::Resource', state: 'success')
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 59).and_return(pr_response_body)
      allow(github_mock).to receive(:combined_status)
        .with('osuosl/packer-templates', 'git-sha').and_return(commit_response_body)
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 59).and_return(response_body)
      payload = open_fixture('issue_packer_templates.json')
      expect { puts PackerPipeline.new.process_payload(payload).to_json }.to output(/"pr":59/).to_stdout
      expect { puts PackerPipeline.new.process_payload(payload).to_json }.to output(/"event_type":"issue"/).to_stdout
      expect { puts PackerPipeline.new.process_payload(payload).to_json }.to output(/"pr_state":"success"/).to_stdout
    end
    it 'outputs the name of a template file' do
      file = fixture_path('centos-7.2-ppc64-openstack.json')
      response_body = [double('Sawyer::Resource', filename: file)]
      head_response = { sha: 'git-sha' }
      contents_response = { head: double('Sawyer::Resource', head_response) }
      pr_response_body = double('Sawyer::Resource', contents_response)
      commit_response_body = double('Sawyer::Resource', state: 'success')
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 16).and_return(pr_response_body)
      allow(github_mock).to receive(:combined_status)
        .with('osuosl/packer-templates', 'git-sha').and_return(commit_response_body)
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      payload = open_fixture('sync_packer_templates.json')
      expect do
        puts PackerPipeline.new.process_payload(payload).to_json
      end.to output(/centos-7.2-ppc64-openstack.json/).to_stdout
    end
    it 'outputs the name of a template file w/ issue payload' do
      file = fixture_path('centos-7.2-ppc64-openstack.json')
      response_body = [double('Sawyer::Resource', filename: file)]
      head_response = { sha: 'git-sha' }
      contents_response = { head: double('Sawyer::Resource', head_response) }
      pr_response_body = double('Sawyer::Resource', contents_response)
      commit_response_body = double('Sawyer::Resource', state: 'success')
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 59).and_return(pr_response_body)
      allow(github_mock).to receive(:combined_status)
        .with('osuosl/packer-templates', 'git-sha').and_return(commit_response_body)
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 59).and_return(response_body)
      payload = open_fixture('issue_packer_templates.json')
      expect do
        puts PackerPipeline.new.process_payload(payload).to_json
      end.to output(/centos-7.2-ppc64-openstack.json/).to_stdout
    end
    it 'finds a template that uses a script' do
      file = 'scripts/centos/osuosl.sh'
      response_body = [double('Sawyer::Resource', filename: file)]
      head_response = { sha: 'git-sha' }
      contents_response = { head: double('Sawyer::Resource', head_response) }
      pr_response_body = double('Sawyer::Resource', contents_response)
      commit_response_body = double('Sawyer::Resource', state: 'success')
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 16).and_return(pr_response_body)
      allow(github_mock).to receive(:combined_status)
        .with('osuosl/packer-templates', 'git-sha').and_return(commit_response_body)
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      payload = open_fixture('sync_packer_templates.json')
      expect do
        puts PackerPipeline.new.process_payload(payload).to_json
      end.to output(/centos-7.3-x86_64-openstack.json/).to_stdout
    end
    it 'finds a template that uses a script w/ issue payload' do
      file = 'scripts/centos/osuosl.sh'
      response_body = [double('Sawyer::Resource', filename: file)]
      head_response = { sha: 'git-sha' }
      contents_response = { head: double('Sawyer::Resource', head_response) }
      pr_response_body = double('Sawyer::Resource', contents_response)
      commit_response_body = double('Sawyer::Resource', state: 'success')
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 59).and_return(pr_response_body)
      allow(github_mock).to receive(:combined_status)
        .with('osuosl/packer-templates', 'git-sha').and_return(commit_response_body)
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 59).and_return(response_body)
      payload = open_fixture('issue_packer_templates.json')
      expect do
        puts PackerPipeline.new.process_payload(payload).to_json
      end.to output(/centos-7.3-x86_64-openstack.json/).to_stdout
    end
    it 'outputs name of template file and finds a template that uses a script' do
      template = fixture_path('centos-7.2-ppc64-openstack.json')
      script = 'scripts/centos/osuosl.sh'
      response_body = [
        double('Sawyer::Resource', filename: template),
        double('Sawyer::Resource', filename: script),
      ]
      head_response = { sha: 'git-sha' }
      contents_response = { head: double('Sawyer::Resource', head_response) }
      pr_response_body = double('Sawyer::Resource', contents_response)
      commit_response_body = double('Sawyer::Resource', state: 'success')
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 16).and_return(pr_response_body)
      allow(github_mock).to receive(:combined_status)
        .with('osuosl/packer-templates', 'git-sha').and_return(commit_response_body)
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      payload = open_fixture('sync_packer_templates.json')
      expect do
        puts PackerPipeline.new.process_payload(payload).to_json
      end.to output(/centos-7.3-x86_64-openstack.json/).to_stdout
      expect do
        puts PackerPipeline.new.process_payload(payload).to_json
      end.to output(/centos-7.2-ppc64-openstack.json/).to_stdout
    end
    it 'outputs name of template file and finds a template that uses a script w/ issue payload' do
      template = fixture_path('centos-7.2-ppc64-openstack.json')
      script = 'scripts/centos/osuosl.sh'
      response_body = [
        double('Sawyer::Resource', filename: template),
        double('Sawyer::Resource', filename: script),
      ]
      head_response = { sha: 'git-sha' }
      contents_response = { head: double('Sawyer::Resource', head_response) }
      pr_response_body = double('Sawyer::Resource', contents_response)
      commit_response_body = double('Sawyer::Resource', state: 'success')
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 59).and_return(pr_response_body)
      allow(github_mock).to receive(:combined_status)
        .with('osuosl/packer-templates', 'git-sha').and_return(commit_response_body)
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 59).and_return(response_body)
      payload = open_fixture('issue_packer_templates.json')
      expect do
        puts PackerPipeline.new.process_payload(payload).to_json
      end.to output(/centos-7.3-x86_64-openstack.json/).to_stdout
      expect do
        puts PackerPipeline.new.process_payload(payload).to_json
      end.to output(/centos-7.2-ppc64-openstack.json/).to_stdout
    end
  end

  context '#commit_status' do
    let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('BUILD_URL').and_return(
        'https://jenkins.osuosl.org/job/packer_pipeline/1/'
      )
      allow(ENV).to receive(:[]).with('GIT_COMMIT').and_return(
        '28256684538cbdde31d0e33829e6d9054b8130de'
      )
    end

    it 'sets the status for a single template' do
      final_results = open_fixture('final_results_single_template.json')

      allow(github_mock).to receive('create_status').with(
        'osuosl/packer-templates',
        '28256684538cbdde31d0e33829e6d9054b8130de',
        'failure',
        context: 'centos-7.3-x86_64-mitaka-aio-openstack.json',
        target_url: 'https://jenkins.osuosl.org/job/packer_pipeline/1/console',
        description: 'builder failed!'
      )

      expect do
        puts PackerPipeline.new.commit_status(final_results)
      end.to output(/builder failed/).to_stdout
    end

    it 'sets the status for multiple templates' do
      final_results = open_fixture('final_results_multiple_templates.json')

      allow(github_mock).to receive('create_status').with(
        'osuosl/packer-templates',
        '28256684538cbdde31d0e33829e6d9054b8130de',
        'success',
        context: 'centos-7.3-x86_64-openstack.json',
        target_url: 'https://jenkins.osuosl.org/job/packer_pipeline/1/console',
        description: 'All passed! {"linter"=>0, "builder"=>0, "deploy_test"=>0, "taster"=>0}'
      )

      allow(github_mock).to receive('create_status').with(
        'osuosl/packer-templates',
        '28256684538cbdde31d0e33829e6d9054b8130de',
        'failure',
        context: 'centos-7.3-x86_64-mitaka-aio-openstack.json',
        target_url: 'https://jenkins.osuosl.org/job/packer_pipeline/1/console',
        description: 'builder failed!'
      )
      expected_output = <<-OUTPUT
{"centos-7.3-x86_64-mitaka-aio-openstack.json"=>{:options=>{:context=>"centos-7.3-x86_64-mitaka-aio-openstack.json", :target_url=>"https://jenkins.osuosl.org/job/packer_pipeline/1/console", :description=>"builder failed!"}, :state=>"failure"}, "centos-7.3-x86_64-openstack.json"=>{:options=>{:context=>"centos-7.3-x86_64-openstack.json", :target_url=>"https://jenkins.osuosl.org/job/packer_pipeline/1/console", :description=>"All passed! {\\"linter\\"=>0, \\"builder\\"=>0, \\"deploy_test\\"=>0, \\"taster\\"=>0}"}, :state=>"success"}}
OUTPUT
      expect do
        puts PackerPipeline.new.commit_status(final_results)
      end.to output(expected_output).to_stdout
    end
  end
  context '#production_deploy' do
    let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
      allow(STDOUT).to receive(:puts)
    end

    it 'Merges PR and deletes branch on !deploy' do
      head_response = {
        sha: '28256684538cbdde31d0e33829e6d9054b8130de',
        ref: 'joe/awesome-branch',
      }
      contents_response = {
        head: double('Sawyer::Resource', head_response),
        merged: false,
        mergeable: true,
      }
      response_body = double('Sawyer::Resource', contents_response)
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 59).and_return(response_body)
      expect(github_mock).to receive(:merge_pull_request).with('osuosl/packer-templates', 59)
      expect(github_mock).to receive(:delete_branch).with('osuosl/packer-templates', 'joe/awesome-branch')
      PackerPipeline.new.production_deploy(59)
    end
    it 'Does NOT merge PR nor deletes branch if already merged' do
      head_response = {
        sha: '28256684538cbdde31d0e33829e6d9054b8130de',
        ref: 'joe/awesome-branch',
      }
      contents_response = {
        head: double('Sawyer::Resource', head_response),
        merged: true,
        mergeable: true,
      }
      response_body = double('Sawyer::Resource', contents_response)
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 59).and_return(response_body)
      allow(github_mock).to receive(:add_comment).with(
        'osuosl/packer-templates',
        59,
        'Error: Cannot merge PR because it has already been merged.'
      )
      expect(github_mock).to_not receive(:merge_pull_request).with('osuosl/packer-templates', 59)
      expect(github_mock).to_not receive(:delete_branch).with('osuosl/packer-templates', 'joe/awesome-branch')
      begin
        PackerPipeline.new.production_deploy(59)
        PackerPipeline.new.abort_comment('error comment', 59)
        expect(github_mock).to receive(:add_comment).with(
          'osuosl/packer-templates',
          59,
          'Error: Cannot merge PR because it has already been merged.'
        )
      rescue SystemExit => e
        expect(e.status).to eq 1
      end
    end
    it 'Does NOT merge PR nor deletes branch if not mergeable' do
      head_response = {
        sha: '28256684538cbdde31d0e33829e6d9054b8130de',
        ref: 'joe/awesome-branch',
      }
      contents_response = {
        head: double('Sawyer::Resource', head_response),
        merged: false,
        mergeable: false,
      }
      response_body = double('Sawyer::Resource', contents_response)
      allow(github_mock).to receive(:pull_request).with('osuosl/packer-templates', 59).and_return(response_body)
      allow(github_mock).to receive(:add_comment).with(
        'osuosl/packer-templates',
        59,
        'Error: Cannot merge PR because it would create merge conflicts.'
      )
      expect(github_mock).to_not receive(:merge_pull_request).with('osuosl/packer-templates', 59)
      expect(github_mock).to_not receive(:delete_branch).with('osuosl/packer-templates', 'joe/awesome-branch')
      begin
        PackerPipeline.new.production_deploy(59)
        PackerPipeline.new.abort_comment('error comment', 59)
        expect(github_mock).to receive(:add_comment).with(
          'osuosl/packer-templates',
          59,
          'Error: Cannot merge PR because it would create merge conflicts.'
        )
      rescue SystemExit => e
        expect(e.status).to eq 1
      end
    end
  end
end
