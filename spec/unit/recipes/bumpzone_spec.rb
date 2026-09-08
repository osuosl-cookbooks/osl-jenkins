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

      it { is_expected.to install_package 'bind' }
      it { is_expected.to nothing_osl_jenkins_service 'bumpzone' }
      it { is_expected.to install_osl_jenkins_plugin 'github-branch-source' }
      it { is_expected.to install_osl_jenkins_plugin 'generic-webhook-trigger' }

      # Intentionally NOT managed by JCasC (created out-of-band); a JCasC
      # credentials block would wipe the server's entire credential store.
      it { is_expected.to_not create_osl_jenkins_password_credentials('bumpzone') }

      it do
        is_expected.to create_osl_jenkins_job('zonefiles').with(
          source: 'jobs/zonefiles_pipeline.groovy.erb',
          template: true,
          variables: {
            job_name: 'zonefiles',
            repo_name: 'zonefiles',
            repo_owner: 'osuosl',
          }
        )
      end

      it do
        is_expected.to create_osl_jenkins_job('zone-bumper').with(
          source: 'jobs/zone_bumper_pipeline.groovy.erb',
          template: true,
          sensitive: true,
          variables: {
            github_url: 'https://github.com/osuosl/zonefiles.git',
            job_name: 'zone-bumper',
            pipelines_branch: 'master',
            repo: 'osuosl/zonefiles',
            trigger_token: 'trigger_token',
          }
        )
      end

      it do
        is_expected.to create_osl_jenkins_job('update-zonefiles').with(
          source: 'jobs/update_zonefiles_pipeline.groovy.erb',
          template: true,
          variables: {
            dns_primary: 'dns_primary',
            github_url: 'https://github.com/osuosl/zonefiles.git',
            job_name: 'update-zonefiles',
            pipelines_branch: 'master',
          }
        )
      end

      %w(zonefiles zone-bumper update-zonefiles).each do |j|
        it do
          expect(chef_run.osl_jenkins_job(j)).to notify('osl_jenkins_service[bumpzone]').to(:restart).delayed
        end
      end

      # The freestyle jobs and the scripts the cookbook used to ship are
      # retired; the ruby now lives in the zonefiles repo under scripts/ci.
      %w(bumpzone checkzone).each do |j|
        it { is_expected.to delete_osl_jenkins_job(j) }
      end

      %w(
        /var/lib/jenkins/bin/bumpzone.rb
        /var/lib/jenkins/bin/checkzone.rb
        /var/lib/jenkins/lib/bumpzone.rb
        /var/lib/jenkins/lib/checkzone.rb
        /var/lib/jenkins/lib/yajl_workaround.rb
      ).each do |f|
        it { is_expected.to delete_file(f) }
        it { is_expected.to_not create_cookbook_file(f) }
      end

      # The scripts ran on /opt/cinc's ruby and needed these pinned; the
      # pipelines run on cinc-workstation's omnibus, which already ships them.
      %w(faraday-http-cache git octokit).each do |g|
        it { is_expected.to_not install_chef_gem(g) }
      end
    end
  end
end
