require_relative '../../spec_helper'

describe 'osl-jenkins::github_comment' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.set['osl-jenkins']['credentials']['git'] = {
            'github_comment' => {
              user: 'manatee',
              token: 'token_password'
            }
          }
          node.set['osl-jenkins']['credentials']['jenkins'] = {
            'github_comment' => {
              user: 'manatee',
              pass: 'password',
              trigger_token: 'trigger_token'
            }
          }
        end.converge(described_recipe)
      end
      include_context 'common_stubs'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      %w(/var/lib/jenkins/bin /var/lib/jenkins/lib).each do |d|
        it do
          expect(chef_run).to create_directory(d).with(recursive: true)
        end
      end
      it do
        expect(chef_run).to create_cookbook_file('/var/lib/jenkins/bin/github_comment.rb')
          .with(
            source: 'bin/github_comment.rb',
            owner: 'jenkins',
            group: 'jenkins',
            mode: 0550
          )
      end
      it do
        expect(chef_run).to create_cookbook_file('/var/lib/jenkins/lib/github_comment.rb')
          .with(
            source: 'lib/github_comment.rb',
            owner: 'jenkins',
            group: 'jenkins',
            mode: 0440
          )
      end
      %w(git octokit).each do |g|
        it do
          expect(chef_run).to install_chef_gem(g).with(compile_time: true)
        end
      end
      {
        'git' => '3.2.0',
        'github' => '1.26.2',
        'ghprb' => '1.35.0'
      }.each do |plugin, ver|
        it do
          expect(chef_run).to install_jenkins_plugin(plugin).with(version: ver)
        end
      end
    end
  end
end
