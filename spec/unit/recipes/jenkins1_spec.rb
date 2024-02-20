require_relative '../../spec_helper'

describe 'osl-jenkins::jenkins1' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.normal['osl-jenkins']['cookbook_uploader'] = {
            'org' => 'osuosl-cookbooks',
            'chef_repo' => 'osuosl/chef-repo',
            'authorized_teams' => %w(osuosl-cookbooks/staff),
            'default_environments' => %w(production workstation),
            'override_repos' => %w(test-cookbook),
            'github_insecure_hook' => true,
            'do_not_upload_cookbooks' => true,
          }
        end.converge(described_recipe)
      end
      include_context 'common_stubs'
      include_context 'cookbook_uploader'
      include_context 'data_bag_stubs'
      before do
        stub_data_bag_item('osl_jenkins', 'jenkins1')
          .and_return(
            'jenkins_private_key' => 'private_key',
            'git' => {
              'cookbook_uploader' => {
                'user' => 'manatee1',
                'token' => 'token_password',
              },
              'bumpzone' => {
                'user' => 'manatee2',
                'token' => 'token_password',
              },
              'github_comment' => {
                'user' => 'manatee3',
                'token' => 'token_password',
              },
            },
            'jenkins' => {
              'cookbook_uploader' => {
                'user' => 'manatee',
                'pass' => 'password',
                'trigger_token' => 'trigger_token',
              },
              'bumpzone' => {
                'user' => 'manatee',
                'api_token' => 'api_token',
                'trigger_token' => 'trigger_token',
              },
              'github_comment' => {
                'user' => 'manatee',
                'pass' => 'password',
                'trigger_token' => 'trigger_token',
              },
            }
          )
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      it do
        is_expected.to create_osl_jenkins_install('jenkins.osuosl.org').with(
          admin_address: 'manatee@osuosl.org',
          num_executors: 4
        )
      end
      it { is_expected.to create_osl_jenkins_config('jenkins1') }
      it do
        expect(chef_run.osl_jenkins_config('jenkins1')).to \
          notify('osl_jenkins_service[jenkins1]').to(:restart).delayed
      end
      it { is_expected.to enable_osl_jenkins_service 'jenkins1' }
      it { is_expected.to start_osl_jenkins_service 'jenkins1' }
      %w(
        base::cinc_workstation
        osl-jenkins::cookbook_uploader
        osl-jenkins::github_comment
        osl-jenkins::bumpzone
        base::python
      ).each do |r|
        it { is_expected.to include_recipe r }
      end
      it { expect(chef_run).to install_package 'graphviz' }
    end
  end
end
