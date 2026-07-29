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
            'override_archived_repos' => %w(archived-cookbook),
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
      include_context 'cookbook_uploader'

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to install_chef_gem('faraday-http-cache').with(version: '< 2.6', compile_time: true) }
      it { is_expected.to install_chef_gem('git').with(version: '< 4', compile_time: true) }
      it { is_expected.to install_chef_gem('octokit').with(version: '< 10', compile_time: true) }

      it do
        is_expected.to create_cookbook_file('/var/lib/jenkins/lib/yajl_workaround.rb')
          .with(
            source: 'lib/yajl_workaround.rb',
            owner: 'jenkins',
            group: 'jenkins',
            mode: '440'
          )
      end

      %w(github_pr_comment_trigger.rb bump_environments.rb).each do |s|
        it do
          expect(chef_run).to create_template("/var/lib/jenkins/bin/#{s}")
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
      it do
        is_expected.to create_osl_jenkins_job('environment-bumper-osuosl-chef-repo').with(
          source: 'jobs/environment-bumper.groovy.erb',
          template: true,
          variables: {
            all_environments_word: '*',
            default_environments_word: '~',
            execute_shell: '/var/lib/jenkins/bin/bump_environments.rb',
            github_url: 'https://github.com/osuosl/chef-repo',
            job_name: 'environment-bumper-osuosl-chef-repo',
            trigger_token: 'trigger_token',
          }
        )
      end
      it do
        expect(chef_run.osl_jenkins_job('environment-bumper-osuosl-chef-repo')).to \
          notify('osl_jenkins_service[cookbook_uploader]').to(:restart).delayed
      end
      it do
        is_expected.to create_osl_jenkins_job('cookbook-uploader-osuosl-cookbooks-test-cookbook').with(
          source: 'jobs/cookbook_uploader.groovy.erb',
          template: true,
          variables: {
            execute_shell: 'echo $payload | /var/lib/jenkins/bin/github_pr_comment_trigger.rb',
            github_url: 'https://github.com/osuosl-cookbooks/test-cookbook',
            job_name: 'cookbook-uploader-osuosl-cookbooks-test-cookbook',
            non_bump_message: 'Exiting because comment was not a bump request',
            trigger_token: 'trigger_token',
          }
        )
      end
      it do
        expect(chef_run.osl_jenkins_job('cookbook-uploader-osuosl-cookbooks-test-cookbook')).to \
          notify('osl_jenkins_service[cookbook_uploader]').to(:restart).delayed
      end
      it { is_expected.to delete_osl_jenkins_job 'cookbook-uploader-osuosl-cookbooks-archived-cookbook' }

      # A Jenkinsfile marks a repo as migrated to the label-driven pipeline:
      # its legacy job config and webhook are removed instead of created.
      context 'when the repo has migrated (Jenkinsfile present)' do
        cached(:migrated_run) do
          ChefSpec::SoloRunner.new(p) do |node|
            node.normal['osl-jenkins']['cookbook_uploader'] = {
              'org' => 'osuosl-cookbooks',
              'chef_repo' => 'osuosl/chef-repo',
              'default_environments' => %w(production workstation),
              'override_repos' => %w(test-cookbook),
              'override_archived_repos' => %w(archived-cookbook),
              'ci_repo_filter' => 'test-cookbook',
              'do_not_upload_cookbooks' => true,
            }
            node.normal['osl-jenkins']['credentials']['git'] = {
              'cookbook_uploader' => { user: 'manatee', token: 'token_password' },
            }
            node.normal['osl-jenkins']['credentials']['jenkins'] = {
              'cookbook_uploader' => {
                user: 'manatee', api_token: 'api_token', trigger_token: 'trigger_token'
              },
            }
          end.converge(described_recipe, 'osl-jenkins::default')
        end

        before do
          allow_any_instance_of(Chef::Recipe).to receive(:repo_has_jenkinsfile?).and_return(true)
        end

        it 'deletes the legacy job config and skips the legacy webhook setup' do
          expect_any_instance_of(Chef::Recipe).to_not receive(:set_up_github_push)
          expect(migrated_run).to delete_osl_jenkins_job('cookbook-uploader-osuosl-cookbooks-test-cookbook')
        end
      end
      it do
        expect(chef_run.osl_jenkins_job('cookbook-uploader-osuosl-cookbooks-archived-cookbook')).to \
          notify('osl_jenkins_service[cookbook_uploader]').to(:restart).delayed
      end
    end
  end
end
