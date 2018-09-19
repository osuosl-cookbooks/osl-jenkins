require_relative '../../spec_helper'

describe 'osl-jenkins::cookbook_uploader' do
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
          node.normal['osl-jenkins']['credentials']['git'] = {
            'cookbook_uploader' => {
              user: 'manatee',
              token: 'token_password',
            },
          }
          node.normal['osl-jenkins']['credentials']['jenkins'] = {
            'cookbook_uploader' => {
              user: 'manatee',
              api_token: 'api_token',
              trigger_token: 'trigger_token',
            },
          }
        end.converge(described_recipe, 'osl-jenkins::default')
      end
      include_context 'common_stubs'
      include_context 'data_bag_stubs'
      include_context 'cookbook_uploader'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      %w(git octokit faraday-http-cache).each do |g|
        it do
          expect(chef_run).to install_chef_gem(g).with(compile_time: true)
        end
      end
      it do
        expect(chef_run).to create_directory('/var/lib/jenkins/bin').with(recursive: true)
      end
      %w(github_pr_comment_trigger.rb bump_environments.rb).each do |s|
        it do
          expect(chef_run).to create_template(::File.join('/var/lib/jenkins/bin', s))
            .with(
              variables: {
                all_environments_word: '*',
                authorized_orgs: [],
                authorized_teams: %w(osuosl-cookbooks/staff),
                authorized_users: [],
                chef_repo: 'osuosl/chef-repo',
                default_environments: %w(production workstation),
                default_environments_word: '~',
                do_not_upload_cookbooks: true,
                github_token: 'token_password',
                non_bump_message: 'Exiting because comment was not a bump request',
              }
            )
        end
      end
      it do
        expect(chef_run).to create_directory('/var/chef/cache/osuosl-cookbooks/test-cookbook').with(recursive: true)
      end
      it do
        expect(chef_run).to create_template('/var/chef/cache/osuosl-cookbooks/test-cookbook/config.xml')
          .with(
            variables: {
              execute_shell: 'echo $payload | /var/lib/jenkins/bin/github_pr_comment_trigger.rb',
              github_url: 'https://github.com/osuosl-cookbooks/test-cookbook',
              non_bump_message: 'Exiting because comment was not a bump request',
              trigger_token: 'trigger_token',
            }
          )
      end
      it do
        expect(chef_run).to create_jenkins_job('cookbook-uploader-osuosl-cookbooks-test-cookbook')
          .with(config: '/var/chef/cache/osuosl-cookbooks/test-cookbook/config.xml')
      end
      it do
        expect(chef_run).to enable_jenkins_job('cookbook-uploader-osuosl-cookbooks-test-cookbook')
          .with(config: '/var/chef/cache/osuosl-cookbooks/test-cookbook/config.xml')
      end
      it do
        expect(chef_run).to create_directory('/var/chef/cache/osuosl/chef-repo').with(recursive: true)
      end
      it do
        expect(chef_run).to create_template('/var/chef/cache/osuosl/chef-repo/config.xml')
          .with(
            variables: {
              all_environments_word: '*',
              default_environments_word: '~',
              execute_shell: '/var/lib/jenkins/bin/bump_environments.rb',
              github_url: 'https://github.com/osuosl/chef-repo',
              trigger_token: 'trigger_token',
            }
          )
      end
      it do
        expect(chef_run).to create_jenkins_job('environment-bumper-osuosl-chef-repo')
          .with(config: '/var/chef/cache/osuosl/chef-repo/config.xml')
      end
      it do
        expect(chef_run).to enable_jenkins_job('environment-bumper-osuosl-chef-repo')
          .with(config: '/var/chef/cache/osuosl/chef-repo/config.xml')
      end
    end
  end
end
