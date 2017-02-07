require_relative '../../spec_helper'

describe 'osl-jenkins::jenkins1' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.set['osl-jenkins']['cookbook_uploader'] = {
            'org' => 'osuosl-cookbooks',
            'chef_repo' => 'osuosl/chef-repo',
            'authorized_teams' => %w(osuosl-cookbooks/staff),
            'default_environments' => %w(production workstation),
            'override_repos' => %w(test-cookbook),
            'github_insecure_hook' => true,
            'do_not_upload_cookbooks' => true
          }
          node.set['osl-jenkins']['credentials']['git'] = {
            'cookbook_uploader' => {
              user: 'manatee',
              token: 'token_password',
              url: 'github.com'
            }
          }
          node.set['osl-jenkins']['credentials']['jenkins'] = {
            'cookbook_uploader' => {
              user: 'manatee',
              pass: 'password',
              trigger_token: 'trigger_token'
            }
          }
        end.converge(described_recipe)
      end
      include_context 'common_stubs'
      include_context 'cookbook_uploader'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      it do
        expect(chef_run).to install_python_runtime(2)
      end
      it do
        expect(chef_run).to install_package('graphviz')
      end
    end
  end
end
