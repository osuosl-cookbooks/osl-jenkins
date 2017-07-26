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
      files = PackerPipeline.changed_files(open_json('sync_packer_templates.json'))
      expect(files.first.filename).to match(/centos-7.3-x86_64-openstack.json/)
    end
    it 'finds multiple changed files' do
      response_body = [
        double('Sawyer::Resource', filename: 'centos-7.3-x86_64-openstack.json'),
        double('Sawyer::Resource', filename: 'centos-7.2-ppc64-openstack.json')
      ]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      files = PackerPipeline.changed_files(open_json('sync_packer_templates.json'))
      expect(files[0].filename).to match(/centos-7.3-x86_64-openstack.json/)
      expect(files[1].filename).to match(/centos-7.2-ppc64-openstack.json/)
    end
  end
  context '#find_dependent_templates' do
    before :each do
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('PACKER_TEMPLATES_DIR').and_return(fixture_path(''))
    end
    it 'returns the name of a template file' do
      file = fixture_path('centos-7.2-ppc64-openstack.json')
      expect( PackerPipeline.find_dependent_templates(file) ).to match_array(['centos-7.2-ppc64-openstack.json'])
    end
    it 'returns a template that uses a script' do
      file = fixture_path('osuosl.sh')
      expect( PackerPipeline.find_dependent_templates(file) ).to match_array(['centos-7.3-x86_64-openstack.json'])
    end
    it 'returns templates that use a script' do
      file = fixture_path('openstack.sh')
      expect( PackerPipeline.find_dependent_templates(file) ).to match_array(
        ['centos-7.3-x86_64-openstack.json','centos-7.2-ppc64-openstack.json']
      )
    end
  end
  context '#start' do
    let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('PACKER_TEMPLATES_DIR').and_return(fixture_path(''))
    end
    it 'prints the PR number' do
      file = fixture_path('osuosl.sh')
      response_body = [double('Sawyer::Resource', filename: file)]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      allow(STDIN).to receive(:read).and_return(open_fixture('sync_packer_templates.json'))
      expect { puts PackerPipeline.start.to_json }.to output(/16/).to_stdout
    end
    it 'ouputs the name of a template file' do
      file = fixture_path('centos-7.2-ppc64-openstack.json')
      response_body = [double('Sawyer::Resource', filename: file)]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      allow(STDIN).to receive(:read).and_return(open_fixture('sync_packer_templates.json'))
      expect { puts PackerPipeline.start.to_json }.to output(/centos-7.2-ppc64-openstack.json/).to_stdout
    end
    it 'finds a template that uses a script' do
      file = fixture_path('osuosl.sh')
      response_body = [double('Sawyer::Resource', filename: file)]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      allow(STDIN).to receive(:read).and_return(open_fixture('sync_packer_templates.json'))
      expect { puts PackerPipeline.start.to_json }.to output(/centos-7.3-x86_64-openstack.json/).to_stdout
    end
    it 'outputs name of template file and finds a template that uses a script' do
      template = fixture_path('centos-7.2-ppc64-openstack.json')
      script = fixture_path('osuosl.sh')
      response_body = [
        double('Sawyer::Resource', filename: template),
        double('Sawyer::Resource', filename: script)
      ]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      allow(STDIN).to receive(:read).and_return(open_fixture('sync_packer_templates.json'))
      expect { puts PackerPipeline.start.to_json }.to output(/centos-7.3-x86_64-openstack.json/).to_stdout
      expect { puts PackerPipeline.start.to_json }.to output(/centos-7.2-ppc64-openstack.json/).to_stdout
    end
  end
end
