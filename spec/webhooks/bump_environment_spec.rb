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

  before :each do
    allow(YAML).to receive(:load_file).with('bump_environments.yml')
        .and_return(open_yaml('bump_environments.yml'))
  end

  context '#load_node_attr' do
    it 'load node attributes' do
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

  context '#load_envs' do
    before :each do
      allow(ENV).to receive(:[]).with('cookbook').and_return('cookbooks')
      allow(ENV).to receive(:[]).with('version').and_return('version')
      allow(ENV).to receive(:[]).with('pr_link').and_return('pr_link')
      allow(ENV).to receive(:[]).with('envs'). and_return('env1,env2')
    end
    it 'loads environment variables' do
      expect(BumpEnvironments.cookbook).to be_nil
      expect(BumpEnvironments.version).to be_nil
      expect(BumpEnvironments.pr_link).to be_nil
      expect(BumpEnvironments.chef_envs).to be_nil
      BumpEnvironments.load_envs
      expect(BumpEnvironments.cookbook).to match(/cookbooks/)
      expect(BumpEnvironments.version).to match(/version/)
      expect(BumpEnvironments.pr_link).to match(/pr_link/)
      puts BumpEnvironments.chef_envs
      expect(BumpEnvironments.chef_envs).to eql(['env1', 'env2'].to_set)
    end
  end

  context '#verify_default_chef_envs' do
    before :each do
      allow(ENV).to receive(:[]).with('cookbook').and_return('cookbooks')
      allow(ENV).to receive(:[]).with('version').and_return('version')
      allow(ENV).to receive(:[]).with('pr_link').and_return('pr_link')
    end
    it 'only includes default environments' do
      allow(ENV).to receive(:[]).with('envs').and_return('~')
      BumpEnvironments.load_node_attr
      BumpEnvironments.load_envs
      BumpEnvironments.verify_default_chef_envs
      expect(BumpEnvironments.chef_envs).to contain_exactly(
        'openstack_mitaka', 'phase_out_nginx', 'phpbb', 'production', 'testing', 'workstation'
      )
      expect(BumpEnvironments.is_default_envs).to be true
    end
    it 'includes default and additional environments' do
      allow(ENV).to receive(:[]).with('envs').and_return('~,extra_env')
      BumpEnvironments.load_node_attr
      BumpEnvironments.load_envs
      BumpEnvironments.verify_default_chef_envs
      expect(BumpEnvironments.chef_envs).to contain_exactly(
        'openstack_mitaka', 'phase_out_nginx', 'phpbb', 'production', 'testing', 'workstation',
        'extra_env'
      )
      expect(BumpEnvironments.is_default_envs).to be false
    end
    it 'does not include default environment at all' do
      allow(ENV).to receive(:[]).with('envs').and_return('extra_env')
      BumpEnvironments.load_node_attr
      BumpEnvironments.load_envs
      BumpEnvironments.verify_default_chef_envs
      expect(BumpEnvironments.chef_envs).to contain_exactly('extra_env')
      expect(BumpEnvironments.is_default_envs).to be false
    end
  end

  context '#verify_all_chef_envs' do
  end
  

#  context '#verify_chef_env' do
#    before :each do
#      allow(ENV).to receive(:[]).with('cookbook').and_return('cookbooks')
#      allow(ENV).to receive(:[]).with('version').and_return('version')
#      allow(ENV).to receive(:[]).with('pr_link').and_return('pr_link')
#      allow(ENV).to receive(:[]).with('envs').and_return('envs')
#    end
#    it 'calls verify functions' do
#      BumpEnvironments.load_envs
#      BumpEnvironments.verify_chef_envs
#      #expect(BumpEnvironments).to receive(:verify_default_chef_envs)
#      expect(BumpEnvironments).to receive(:verify_all_chef_envs)
#    end
#  end
end
