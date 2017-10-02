require_relative '../../spec_helper'

describe 'osl-jenkins::powerci' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common_stubs'
      before do
        stub_data_bag_item('osl_jenkins', 'powerci').and_return(
          admin_users: ['testadmin'],
          normal_users: ['testuser'],
          client_id: '123456789',
          client_secret: '0987654321',
          cli_password: 'abcdefghi'
        )
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      %w(
        build-monitor-plugin:1.11+build.201701152243
        cloud-stats:0.11
        config-file-provider:2.16.2
        docker-commons:1.8
        docker-plugin:0.16.2
        docker-build-publish:1.3.2
        email-ext:2.57.2
        emailext-template:1.0
        embeddable-build-status:1.9
        git-client:2.5.0
        github-api:1.86
        github-oauth:0.27
        job-restrictions:0.6
        matrix-project:1.10
        openstack-cloud:2.22
        pipeline-multibranch-defaults:1.1
        resource-disposer:0.6
      ).each do |plugins_version|
        plugin, version = plugins_version.split(':')
        it do
          expect(chef_run).to install_jenkins_plugin(plugin).with(
            version: version,
            install_deps: false
          )
        end
        it do
          expect(chef_run.jenkins_plugin(plugin)).to notify('jenkins_command[safe-restart]')
        end
      end
      it do
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
      end
      it do
        expect(chef_run).to execute_jenkins_script('Add GitHub OAuth config')
      end
      it do
        expect(chef_run).to execute_jenkins_script('Add OpenStack Cloud')
      end
      it do
        expect(chef_run).to run_ruby_block('Set jenkins username/password if needed')
      end
    end
  end
end
