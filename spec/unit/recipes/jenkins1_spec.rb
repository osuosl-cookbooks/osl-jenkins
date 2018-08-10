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
              'packer_pipeline' => {
                'user' => 'manatee',
                'api_token' => 'token_password',
                'trigger_token' => 'trigger_token',
                'public_key' => 'public key for openstack_taster goes here',
                'private_key' => 'private key for openstack_taster goes here',
              },
            }
          )
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      it do
        expect(chef_run).to create_jenkins_password_credentials('manatee1').with(
          id: 'cookbook_uploader',
          password: 'token_password'
        )
      end
      it do
        expect(chef_run).to create_jenkins_password_credentials('manatee2').with(
          id: 'bumpzone',
          password: 'token_password'
        )
      end
      it do
        expect(chef_run).to create_jenkins_password_credentials('manatee3').with(
          id: 'github_comment',
          password: 'token_password'
        )
      end
      it do
        expect(chef_run).to install_python_runtime('2')
      end
      it do
        expect(chef_run).to install_package('graphviz')
      end
    end
  end
end
