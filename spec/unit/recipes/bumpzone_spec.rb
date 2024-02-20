require_relative '../../spec_helper'

describe 'osl-jenkins::bumpzone' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.normal['osl-jenkins']['credentials']['git'] = {
            'bumpzone' => {
              user: 'manatee',
              token: 'token_password',
            },
          }
          node.normal['osl-jenkins']['credentials']['jenkins'] = {
            'bumpzone' => {
              user: 'manatee',
              api_token: 'api_token',
              trigger_token: 'trigger_token',
            },
          }
        end.converge(described_recipe)
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

      %w(bumpzone.rb checkzone.rb).each do |f|
        it do
          is_expected.to create_cookbook_file("/var/lib/jenkins/bin/#{f}")
            .with(
              source: "bin/#{f}",
              owner: 'jenkins',
              group: 'jenkins',
              mode: '550'
            )
        end
        it do
          is_expected.to create_cookbook_file("/var/lib/jenkins/lib/#{f}")
            .with(
              source: "lib/#{f}",
              owner: 'jenkins',
              group: 'jenkins',
              mode: '440'
            )
        end
      end
      it { is_expected.to install_package 'bind' }
      it { is_expected.to nothing_osl_jenkins_service 'bumpzone' }
      it { is_expected.to install_osl_jenkins_plugin 'slack' }
      it do
        expect(chef_run.osl_jenkins_plugin('slack')).to notify('osl_jenkins_service[bumpzone]').to(:restart).delayed
      end
      it do
        is_expected.to create_osl_jenkins_password_credentials('bumpzone').with(
          username: 'manatee',
          password: 'token_password'
        )
      end
      it do
        expect(chef_run.osl_jenkins_password_credentials('bumpzone')).to \
          notify('osl_jenkins_service[bumpzone]').to(:restart).delayed
      end
    end
  end
end
