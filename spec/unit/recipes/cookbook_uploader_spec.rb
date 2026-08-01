require_relative '../../spec_helper'

describe 'osl-jenkins::cookbook_uploader' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.normal['osl-jenkins']['cookbook_uploader'] = {
            'org' => 'osuosl-cookbooks',
            'chef_repo' => 'osuosl/chef-repo',
            'default_environments' => %w(production workstation),
            'override_repos' => %w(test-cookbook),
            'ci_repo_filter' => 'test-cookbook',
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

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to nothing_osl_jenkins_service 'cookbook_uploader' }
      it { is_expected.to install_osl_jenkins_plugin 'github-branch-source' }
      it { is_expected.to install_osl_jenkins_plugin 'generic-webhook-trigger' }
      it { is_expected.to install_osl_jenkins_plugin 'pipeline-utility-steps' }
      it do
        is_expected.to create_osl_jenkins_job('cookbook-uploader').with(
          source: 'jobs/cookbook_uploader_pipeline.groovy.erb',
          template: true,
          variables: {
            chef_repo: 'osuosl/chef-repo',
            default_environments: 'production,workstation',
            do_not_upload: 'true',
            job_name: 'cookbook-uploader',
            org: 'osuosl-cookbooks',
            pipelines_branch: 'main',
            pipelines_repo: 'https://github.com/osuosl/cookbook-pipelines.git',
            trigger_token: 'trigger_token',
          }
        )
      end
      it do
        expect(chef_run.osl_jenkins_job('cookbook-uploader')).to \
          notify('osl_jenkins_service[cookbook_uploader]').to(:restart).delayed
      end
      it do
        is_expected.to create_osl_jenkins_job('environment-bumper').with(
          source: 'jobs/environment_bumper_pipeline.groovy.erb',
          template: true,
          variables: {
            chef_repo: 'osuosl/chef-repo',
            default_environments: 'production,workstation',
            job_name: 'environment-bumper',
            pipelines_branch: 'main',
            pipelines_repo: 'https://github.com/osuosl/cookbook-pipelines.git',
          }
        )
      end
      it do
        expect(chef_run.osl_jenkins_job('environment-bumper')).to \
          notify('osl_jenkins_service[cookbook_uploader]').to(:restart).delayed
      end
      it do
        is_expected.to create_osl_jenkins_job('chef-repo').with(
          source: 'jobs/chef_repo_pipeline.groovy.erb',
          template: true,
          variables: {
            job_name: 'chef-repo',
            repo_owner: 'osuosl',
            repo_name: 'chef-repo',
          }
        )
      end
      it do
        expect(chef_run.osl_jenkins_job('chef-repo')).to \
          notify('osl_jenkins_service[cookbook_uploader]').to(:restart).delayed
      end
      it { is_expected.to install_osl_jenkins_plugin 'gitlab-branch-source' }
      it do
        is_expected.to create_osl_jenkins_config('gitlab_server').with(
          source: 'gitlab_server.yml.erb',
          variables: {
            name: 'git.osuosl.org',
            url: 'https://git.osuosl.org',
            credential_id: 'gitlab-api-token',
          }
        )
      end
      it do
        is_expected.to create_osl_jenkins_job('data-bags').with(
          source: 'jobs/data_bags_pipeline.groovy.erb',
          template: true,
          variables: {
            checkout_credential: '5e204eb3-1907-4a36-8640-fa7ae3cacbf2',
            job_name: 'data-bags',
            project_owner: 'osuosl-chef',
            project_path: 'osuosl-chef/data_bags',
            server_name: 'git.osuosl.org',
          }
        )
      end
      it do
        expect(chef_run.osl_jenkins_job('data-bags')).to \
          notify('osl_jenkins_service[cookbook_uploader]').to(:restart).delayed
      end
      it do
        is_expected.to create_osl_jenkins_job('github-sync').with(
          source: 'jobs/github_sync_pipeline.groovy.erb',
          template: true,
          variables: {
            default_environments: 'production,workstation',
            insecure_hook: 'true',
            job_name: 'github-sync',
            org: 'osuosl-cookbooks',
            pipelines_branch: 'main',
            pipelines_repo: 'https://github.com/osuosl/cookbook-pipelines.git',
            repos: 'test-cookbook',
            webhook_endpoint: 'https://jenkins.osuosl.org/generic-webhook-trigger/invoke',
          }
        )
      end
      it do
        expect(chef_run.osl_jenkins_job('github-sync')).to \
          notify('osl_jenkins_service[cookbook_uploader]').to(:restart).delayed
      end
      # The cookbook_uploader credential is intentionally NOT managed by JCasC
      # (it is created out-of-band); a JCasC credentials block would wipe the
      # server's entire credential store on restart.
      it { is_expected.to_not create_osl_jenkins_password_credentials('cookbook_uploader') }
      it do
        is_expected.to create_osl_jenkins_config('shared_library').with(
          source: 'shared_library.yml.erb',
          variables: {
            branch: 'main',
            repo: 'https://github.com/osuosl/cookbook-pipelines.git',
          }
        )
      end
      it do
        is_expected.to create_osl_jenkins_job('osuosl-cookbooks').with(
          source: 'jobs/cookbook_ci.groovy.erb',
          template: true,
          variables: {
            job_name: 'osuosl-cookbooks',
            org: 'osuosl-cookbooks',
            repo_filter: 'test-cookbook',
          }
        )
      end
      it do
        expect(chef_run.osl_jenkins_job('osuosl-cookbooks')).to \
          notify('osl_jenkins_service[cookbook_uploader]').to(:restart).delayed
      end
      # One-time cleanup of the retired freestyle environment bumper config
      # and the legacy trigger scripts.
      it { is_expected.to delete_osl_jenkins_job 'environment-bumper-osuosl-chef-repo' }
      it do
        expect(chef_run.osl_jenkins_job('environment-bumper-osuosl-chef-repo')).to \
          notify('osl_jenkins_service[cookbook_uploader]').to(:restart).delayed
      end
      %w(github_pr_comment_trigger.rb bump_environments.rb).each do |s|
        it { is_expected.to delete_file("/var/lib/jenkins/bin/#{s}") }
      end
    end
  end
end
