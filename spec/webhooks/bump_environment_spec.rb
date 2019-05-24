require 'rspec'
require 'rspec/mocks'
require 'tempfile'
require 'pathname'
require 'yaml'
require 'json'
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

  def glob_env_files
    Dir.glob(fixture_path('environments/*.json')).map do |f|
      f.sub(%r{(.*)\/environments\/(.*)\.json}, 'environments/\2.json')
    end
  end

  def get_cookbook_version(file, cookbook)
    data = JSON.parse(::File.read(fixture_path(file)))
    data['cookbook_versions'][cookbook]
  end

  def revert_environments()
    update_environment('openstack_ocata.json', 'cookbook', '= 0.7.0')
    update_environment('phpbb.json', 'cookbook', '= 0.7.0')
    update_environment('production.json', 'cookbook', nil)
    update_environment('workstation.json', 'cookbook', nil)
  end

  def update_environment(file, cookbook, version)
    file = 'environments/' + file
    data = JSON.parse(::File.read(fixture_path(file)))
    if version
      data['cookbook_versions'][cookbook] = version
    else
      data['cookbook_versions'].delete(cookbook)
    end
    ::File.write(fixture_path(file), JSON.pretty_generate(data) + "\n")
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
  let(:git_mock) { double('Git::Base') }
  let(:git_remote_mock) { double('Git::Remote') }

  before :each do
    allow(ENV).to receive(:[]).with('cookbook').and_return('cookbook')
    allow(ENV).to receive(:[]).with('version').and_return('1.0.0')
    allow(ENV).to receive(:[]).with('pr_link').and_return('pr_link')
    allow(Dir).to receive(:glob).with('environments/*.json').and_return(glob_env_files)
    allow(YAML).to receive(:load_file).with('bump_environments.yml')
                                      .and_return(open_yaml('bump_environments.yml'))
    allow(git_mock).to receive(:branch).and_return(git_mock)
    allow(git_mock).to receive(:checkout)
    allow(git_mock).to receive(:pull)
    allow(git_mock).to receive(:add).with(all: true)
    allow(git_mock).to receive(:remote).with('origin').and_return(git_remote_mock)
    allow(git_mock).to receive(:commit)
    allow(git_mock).to receive(:push)
    allow(Git).to receive(:open).and_return(git_mock)
    allow(Octokit::Client).to receive(:new) { github_mock }
    allow(github_mock).to receive(:create_pull_request)
  end

  context '#load_node_attr' do
    it 'load node attributes' do
      expect(BumpEnvironments.default_chef_envs).to be_nil
      expect(BumpEnvironments.default_chef_envs_word).to be_nil
      expect(BumpEnvironments.all_chef_envs_word).to be_nil
      expect(BumpEnvironments.chef_repo).to be_nil
      expect(BumpEnvironments.github_token).to be_nil
      BumpEnvironments.load_node_attr
      expect(BumpEnvironments.default_chef_envs).to contain_exactly(
        'openstack_mitaka', 'phase_out_nginx', 'phpbb', 'production', 'testing', 'workstation'
      )
      expect(BumpEnvironments.default_chef_envs_word).to match(/~/)
      expect(BumpEnvironments.all_chef_envs_word).to match(/\*/)
      expect(BumpEnvironments.chef_repo).to match(%r{osuosl\/chef-repo})
      expect(BumpEnvironments.github_token).to match(/github_token/)
    end
  end

  context '#load_envs' do
    before :each do
      allow(ENV).to receive(:[]).with('envs'). and_return('phpbb,production')
    end
    it 'loads environment variables' do
      expect(BumpEnvironments.cookbook).to be_nil
      expect(BumpEnvironments.version).to be_nil
      expect(BumpEnvironments.pr_link).to be_nil
      expect(BumpEnvironments.chef_envs).to be_nil
      BumpEnvironments.load_envs
      expect(BumpEnvironments.cookbook).to match(/cookbook/)
      expect(BumpEnvironments.version).to match(/1\.0\.0/)
      expect(BumpEnvironments.pr_link).to match(/pr_link/)
      expect(BumpEnvironments.chef_envs).to eql(%w(phpbb production).to_set)
    end
  end

  context '#load_config' do
    it 'calls load_config' do
      allow(ENV).to receive(:[]).with('envs').and_return('phpbb,production')
      expect(BumpEnvironments).to receive(:load_node_attr)
      expect(BumpEnvironments).to receive(:load_envs)
      BumpEnvironments.load_config
    end
  end

  context '#verify_default_chef_envs' do
    it 'only includes default environments' do
      allow(ENV).to receive(:[]).with('envs').and_return('~')
      BumpEnvironments.load_config
      BumpEnvironments.verify_default_chef_envs
      expect(BumpEnvironments.chef_envs).to contain_exactly(
        'openstack_mitaka', 'phase_out_nginx', 'phpbb', 'production', 'testing', 'workstation'
      )
      expect(BumpEnvironments.is_default_envs).to be true
    end
    it 'includes default and additional environments' do
      allow(ENV).to receive(:[]).with('envs').and_return('~,extra_env')
      BumpEnvironments.load_config
      BumpEnvironments.verify_default_chef_envs
      expect(BumpEnvironments.chef_envs).to contain_exactly(
        'openstack_mitaka', 'phase_out_nginx', 'phpbb', 'production', 'testing', 'workstation',
        'extra_env'
      )
      expect(BumpEnvironments.is_default_envs).to be false
    end
    it 'does not include default environment at all' do
      allow(ENV).to receive(:[]).with('envs').and_return('env')
      BumpEnvironments.load_config
      BumpEnvironments.verify_default_chef_envs
      expect(BumpEnvironments.chef_envs).to contain_exactly('env')
      expect(BumpEnvironments.is_default_envs).to be false
    end
  end

  context '#verify_all_chef_envs' do
    it 'includes all environments' do
      allow(ENV).to receive(:[]).with('envs').and_return('*')
      BumpEnvironments.load_config
      BumpEnvironments.verify_all_chef_envs
      expect(BumpEnvironments.is_all_envs).to be true
      expect(BumpEnvironments.chef_env_files).to contain_exactly(
        'environments/openstack_ocata.json', 'environments/phpbb.json',
        'environments/production.json', 'environments/workstation.json'
      )
      expect(BumpEnvironments.chef_envs).to contain_exactly(
        'openstack_ocata', 'phpbb', 'production', 'workstation'
      )
    end
    it 'not include all environments' do
      allow(ENV).to receive(:[]).with('envs').and_return('phpbb,production')
      BumpEnvironments.load_config
      BumpEnvironments.verify_all_chef_envs
      expect(BumpEnvironments.is_all_envs).to be false
      expect(BumpEnvironments.chef_envs).to contain_exactly('phpbb', 'production')
      expect(BumpEnvironments.chef_env_files).to contain_exactly(
        'environments/phpbb.json', 'environments/production.json'
      )
    end
  end

  context '#verify_chef_envs' do
    before :each do
      allow(ENV).to receive(:[]).with('envs').and_return('envs')
    end
    it 'very defaults and chef envs' do
      expect(BumpEnvironments).to receive(:verify_default_chef_envs)
      expect(BumpEnvironments).to receive(:verify_all_chef_envs)
      expect(BumpEnvironments.is_all_envs).not_to be_nil
      expect(BumpEnvironments.is_default_envs).not_to be_nil
      BumpEnvironments.verify_chef_envs
    end
  end

  context '#update_master' do
    it 'updates master branch' do
      expect(git_mock).to receive(:branch).with('master').and_return(git_mock)
      expect(git_mock).to receive(:checkout)
      expect(git_mock).to receive(:pull).with('origin', 'master')
      BumpEnvironments.update_master(git_mock)
    end
  end

  context '#create_new_branch' do
    it 'creates new branch for all environments' do
      allow(BumpEnvironments).to receive(:create_branch_hash)
        .with('openstack_ocata,phpbb,production,workstation,1.0.0').and_return(12345)
      allow(ENV).to receive(:[]).with('envs').and_return('*')
      expect(git_mock).to receive(:branch).with('jenkins/cookbook-1.0.0-all-envs-12345').and_return(git_mock)
      expect(git_mock).to receive(:checkout)
      BumpEnvironments.load_config
      BumpEnvironments.verify_chef_envs
      BumpEnvironments.update_master(git_mock)
      BumpEnvironments.create_new_branch(git_mock)
    end
    it 'creates new branch for default environments' do
      allow(BumpEnvironments).to receive(:create_branch_hash)
        .with('openstack_mitaka,phase_out_nginx,phpbb,production,testing,workstation,1.0.0').and_return(12345)
      allow(ENV).to receive(:[]).with('envs').and_return('~')
      expect(git_mock).to receive(:branch).with('jenkins/cookbook-1.0.0-default-envs-12345').and_return(git_mock)
      expect(git_mock).to receive(:checkout)
      BumpEnvironments.load_config
      BumpEnvironments.verify_chef_envs
      BumpEnvironments.update_master(git_mock)
      BumpEnvironments.create_new_branch(git_mock)
    end
    it 'creates new branch, not all or default environment' do
      allow(BumpEnvironments).to receive(:create_branch_hash)
        .with('phpbb,production,1.0.0').and_return(12345)
      allow(ENV).to receive(:[]).with('envs').and_return('phpbb,production')
      expect(git_mock).to receive(:branch).with('jenkins/cookbook-1.0.0-12345').and_return(git_mock)
      expect(git_mock).to receive(:checkout)
      BumpEnvironments.load_config
      BumpEnvironments.verify_chef_envs
      BumpEnvironments.update_master(git_mock)
      BumpEnvironments.create_new_branch(git_mock)
    end
  end

  context '#update_env_files' do
    before :each do
      allow(ENV).to receive(:[]).with('envs').and_return('*')
    end
    it 'update cookbook versions from all environment files' do
      BumpEnvironments.load_config
      BumpEnvironments.verify_chef_envs
      BumpEnvironments.chef_env_files = BumpEnvironments.chef_env_files.map do |file|
        fixture_path(file)
      end
      BumpEnvironments.update_env_files
      expect(get_cookbook_version('environments/openstack_ocata.json', BumpEnvironments.cookbook)).to eq('= 1.0.0')
      expect(get_cookbook_version('environments/phpbb.json', BumpEnvironments.cookbook)).to eq('= 1.0.0')
      expect(get_cookbook_version('environments/production.json', BumpEnvironments.cookbook)).to be_nil
      expect(get_cookbook_version('environments/workstation.json', BumpEnvironments.cookbook)).to be_nil
      revert_environments
      expect(get_cookbook_version('environments/openstack_ocata.json', BumpEnvironments.cookbook)).to eq('= 0.7.0')
      expect(get_cookbook_version('environments/phpbb.json', BumpEnvironments.cookbook)).to eq('= 0.7.0')
      expect(get_cookbook_version('environments/production.json', BumpEnvironments.cookbook)).to be_nil
      expect(get_cookbook_version('environments/workstation.json', BumpEnvironments.cookbook)).to be_nil
    end
  end

  context '#update_version' do
    before :each do
      allow(ENV).to receive(:[]).with('envs').and_return('*')
    end
    it 'update cookbook version if cookbook is present in specified file' do
      env_file = 'environments/phpbb.json'
      BumpEnvironments.load_config
      BumpEnvironments.update_version(fixture_path(env_file))
      expect(get_cookbook_version(env_file, BumpEnvironments.cookbook)).to eq('= 1.0.0')
      revert_environments
      expect(get_cookbook_version(env_file, BumpEnvironments.cookbook)).to eq('= 0.7.0')
    end
    it 'does not change environment cookbook version if cookbook not found' do
      env_file = 'environments/production.json'
      BumpEnvironments.update_version(fixture_path(env_file))
      expect(get_cookbook_version(env_file, BumpEnvironments.cookbook)).to be_nil
    end
  end

  context '#push_branch' do
    before :each do
      allow(ENV).to receive(:[]).with('envs').and_return('*')
    end
    it 'has changes to commit' do
      BumpEnvironments.load_config
      expect(git_mock).to receive(:commit).with('Automatic version bump to v1.0.0 by Jenkins')
      expect(git_mock).to receive(:push)
        .with(git_remote_mock, 'jenkins/cookbook-1.0.0-12345', tags: true, force: true)
      BumpEnvironments.push_branch(git_mock, 'jenkins/cookbook-1.0.0-12345')
    end
    it 'has no change to commit' do
      allow(git_mock).to receive(:commit).and_raise(Git::GitExecuteError)
      BumpEnvironments.load_config
      expect(git_mock).to receive(:commit).with('Automatic version bump to v1.0.0 by Jenkins')
      expect(git_mock).to receive(:push)
        .with(git_remote_mock, 'jenkins/cookbook-1.0.0-12345', tags: true, force: true)
      expect { BumpEnvironments.push_branch(git_mock, 'jenkins/cookbook-1.0.0-12345') }
        .to output("Unable to commit; were any changes actually made?\n").to_stderr
    end
  end

  context '#create_pr' do
    it 'creates pr for all environments' do
      allow(ENV).to receive(:[]).with('envs').and_return('*')
      BumpEnvironments.load_config
      BumpEnvironments.verify_chef_envs
      expect(github_mock).to receive(:create_pull_request)
        .with(
          'osuosl/chef-repo',
          'master',
          'jenkins/cookbook-1.0.0-12345',
          "Bump 'cookbook' cookbook to version 1.0.0",
          "This automatically generated PR bumps the 'cookbook' cookbook to version 1.0.0 in all "\
          "environments.\nThis new version includes the changes from this PR: pr_link."
        )
      BumpEnvironments.create_pr('jenkins/cookbook-1.0.0-12345')
    end
    it 'creates pr for default environments' do
      allow(ENV).to receive(:[]).with('envs').and_return('~')
      BumpEnvironments.load_config
      BumpEnvironments.verify_chef_envs
      expect(github_mock).to receive(:create_pull_request)
        .with(
          'osuosl/chef-repo',
          'master',
          'jenkins/cookbook-1.0.0-12345',
          "Bump 'cookbook' cookbook to version 1.0.0",
          "This automatically generated PR bumps the 'cookbook' cookbook to version 1.0.0 in the "\
          "default set of environments:\n```\nopenstack_mitaka\nphase_out_nginx\nphpbb\nproduction"\
          "\ntesting\nworkstation\n```\n"\
          'This new version includes the changes from this PR: pr_link.'
        )
      BumpEnvironments.create_pr('jenkins/cookbook-1.0.0-12345')
    end
    it 'creates pr for non-all, non-default environments' do
      allow(ENV).to receive(:[]).with('envs').and_return('phpbb,production')
      BumpEnvironments.load_config
      BumpEnvironments.verify_chef_envs
      expect(github_mock).to receive(:create_pull_request)
        .with(
          'osuosl/chef-repo',
          'master',
          'jenkins/cookbook-1.0.0-12345',
          "Bump 'cookbook' cookbook to version 1.0.0",
          "This automatically generated PR bumps the 'cookbook' cookbook to version 1.0.0 in the "\
          "following environments:\n```\nphpbb\nproduction\n```\n"\
          'This new version includes the changes from this PR: pr_link.'
        )
      BumpEnvironments.create_pr('jenkins/cookbook-1.0.0-12345')
    end
    it 'creates pr when pr_link is nil' do
      allow(ENV).to receive(:[]).with('pr_link').and_return(nil)
      allow(ENV).to receive(:[]).with('envs').and_return('*')
      BumpEnvironments.load_config
      BumpEnvironments.verify_chef_envs
      expect(github_mock).to receive(:create_pull_request)
        .with(
          'osuosl/chef-repo',
          'master',
          'jenkins/cookbook-1.0.0-12345',
          "Bump 'cookbook' cookbook to version 1.0.0",
          "This automatically generated PR bumps the 'cookbook' cookbook to version 1.0.0 in all environments."
        )
      BumpEnvironments.create_pr('jenkins/cookbook-1.0.0-12345')
    end
    it 'creates pr when pr_link is empty' do
      allow(ENV).to receive(:[]).with('pr_link').and_return('')
      allow(ENV).to receive(:[]).with('envs').and_return('*')
      BumpEnvironments.load_config
      BumpEnvironments.verify_chef_envs
      expect(github_mock).to receive(:create_pull_request)
        .with(
          'osuosl/chef-repo',
          'master',
          'jenkins/cookbook-1.0.0-12345',
          "Bump 'cookbook' cookbook to version 1.0.0",
          "This automatically generated PR bumps the 'cookbook' cookbook to version 1.0.0 in all environments."
        )
      BumpEnvironments.create_pr('jenkins/cookbook-1.0.0-12345')
    end
  end

  context '#bump_env' do
    it 'calls bump_env' do
      allow(BumpEnvironments).to receive(:create_new_branch).with(git_mock)
                                                            .and_return('jenkins/cookbook-1.0.0-12345')
      expect(BumpEnvironments).to receive(:update_master).with(git_mock)
      expect(BumpEnvironments).to receive(:create_new_branch).with(git_mock)
      expect(BumpEnvironments).to receive(:update_env_files)
      expect(BumpEnvironments).to receive(:push_branch)
        .with(git_mock, 'jenkins/cookbook-1.0.0-12345')
      expect(BumpEnvironments).to receive(:create_pr).with('jenkins/cookbook-1.0.0-12345')
      BumpEnvironments.bump_env
    end
  end

  context '#start' do
    it 'calls start' do
      expect(BumpEnvironments).to receive(:load_config)
      expect(BumpEnvironments).to receive(:verify_chef_envs)
      expect(BumpEnvironments).to receive(:bump_env)
      BumpEnvironments.start
    end
  end
end
