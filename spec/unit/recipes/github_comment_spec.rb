require_relative '../../spec_helper'

describe 'osl-jenkins::github_comment' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.normal['osl-jenkins']['credentials']['git'] = {
            'github_comment' => {
              user: 'manatee',
              token: 'token_password',
            },
          }
          node.normal['osl-jenkins']['credentials']['jenkins'] = {
            'github_comment' => {
              user: 'manatee',
              pass: 'password',
              trigger_token: 'trigger_token',
            },
          }
        end.converge(described_recipe, 'osl-jenkins::default')
      end
      include_context 'common_stubs'
      include_context 'data_bag_stubs'

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      %w(
        faraday-http-cache
        git
        octokit
      ).each do |g|
        it { is_expected.to install_chef_gem(g).with(compile_time: true) }
      end

      it do
        expect(chef_run).to create_cookbook_file('/var/lib/jenkins/bin/github_comment.rb')
          .with(
            source: 'bin/github_comment.rb',
            owner: 'jenkins',
            group: 'jenkins',
            mode: '550'
          )
      end

      it do
        expect(chef_run).to create_cookbook_file('/var/lib/jenkins/lib/github_comment.rb')
          .with(
            source: 'lib/github_comment.rb',
            owner: 'jenkins',
            group: 'jenkins',
            mode: '440'
          )
      end

      it { is_expected.to nothing_osl_jenkins_service 'github_comment' }
      it { is_expected.to install_osl_jenkins_plugin 'ghprb' }
      it do
        expect(chef_run.osl_jenkins_plugin('ghprb')).to \
          notify('osl_jenkins_service[github_comment]').to(:restart).delayed
      end
      it do
        is_expected.to create_osl_jenkins_job('github_comment').with(
          source: 'jobs/github_comment.groovy',
          file: true
        )
      end
      it do
        expect(chef_run.osl_jenkins_job('github_comment')).to \
          notify('osl_jenkins_service[github_comment]').to(:restart).delayed
      end
    end
  end
end
