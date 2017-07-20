require 'rspec'
require 'rspec/mocks'
require 'tempfile'
require 'pathname'
require_relative '../../files/default/lib/packerpipeline'

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
  context '#start' do
    let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }
    before :each do
      allow(Octokit::Client).to receive(:new) { github_mock }
      allow(ENV).to receive(:[])
      allow(ENV).to receive(:[]).with('PACKER_TEMPLATES_DIR').and_return(fixture_path('').chop)
    end
    it 'ouputs template files put into it' do
      file = fixture_path('centos-7.2-ppc64-openstack.json')
      response_body = [double('Sawyer::Resource', filename: file)]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      allow(STDIN).to receive(:read).and_return(open_fixture('sync_packer_templates.json'))
      expect { PackerPipeline.start }.to output(/CentOS 7.2 Big Endian/).to_stdout
    end
    it 'finds a template that uses a script' do
      file = fixture_path('osuosl.sh')
      response_body = [double('Sawyer::Resource', filename: file)]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      allow(STDIN).to receive(:read).and_return(open_fixture('sync_packer_templates.json'))
      expect { PackerPipeline.start }.to output(/CentOS 7.3 LE/).to_stdout
    end
    it 'prints the PR number' do
      file = fixture_path('osuosl.sh')
      response_body = [double('Sawyer::Resource', filename: file)]
      allow(github_mock).to receive(:pull_request_files).with('osuosl/packer-templates', 16).and_return(response_body)
      allow(STDIN).to receive(:read).and_return(open_fixture('sync_packer_templates.json'))
      expect { PackerPipeline.start }.to output(/16/).to_stdout
    end
  end
end
