require 'rspec'
require 'rspec/mocks'
require 'tempfile'
require 'pathname'
require 'yaml'
require_relative '../../files/default/lib/bump_environments'

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

describe BumpEnvironments do
  let(:github_mock) { double('Octokit', commits: [], issues: [], same_options?: false, auto_paginate: true) }
  context 'load_node_attr' do
    it 'Load node attributes' do
      allow(YAML).to receive(:load_file).with('bump_environments.yml')
          .and_return(open_yaml('bump_environments.yml'))
      BumpEnvironments.load_node_attr
      expect(BumpEnvironments.default_chef_envs).to contain_exactly(
        'openstack_mitaka', 'phase_out_nginx', 'phpbb', 'production', 'testing', 'workstation'
      )
      expect(BumpEnvironments.default_chef_envs_word).to match(/~/)
      expect(BumpEnvironments.all_chef_envs_word).to match(/\*/)
      expect(BumpEnvironments.chef_repo).to match(/osuosl\/chef-repo/)
      expect(BumpEnvironments.github_token).to match(/github_token/)
    end
  end
#  it 'verify chef env' do
#    BumpEnvironments.verify_chef_env
#    expect(self).to receive(:verify_default_chef_env)
#    expect(self).to receive(:verify_all_chef_env)
#  end
end
