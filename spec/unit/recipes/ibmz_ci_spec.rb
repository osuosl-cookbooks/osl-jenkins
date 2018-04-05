require_relative '../../spec_helper'

describe 'osl-jenkins::ibmz_ci' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common_stubs'
      before do
        allow(Chef::EncryptedDataBagItem).to receive(:load).with('osl_jenkins', 'ibmz_ci').and_return(
          admin_users: ['testadmin'],
          normal_users: ['testuser'],
          'oauth' => {
            'ibmz_ci' => {
              client_id: '123456789',
              client_secret: '0987654321'
            }
          },
          'git' => {
            'ibmz_ci' => {
              'user' => 'ibmz_ci',
              'token' => 'ibmz_ci'
            }
          }
        )
        stub_search('node', 'roles:ibmz_ci_docker').and_return(
          [
            {
              ipaddress: '192.168.0.1',
              fqdn: 'docker1.example.org'
            },
            {
              ipaddress: '192.168.0.2',
              fqdn: 'docker2.example.org'
            }
          ]
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
        durable-task:1.17
        email-ext:2.57.2
        emailext-template:1.0
        embeddable-build-status:1.9
        git-client:2.5.0
        github-api:1.90
        github-oauth:0.27
        job-restrictions:0.6
        matrix-project:1.10
        openstack-cloud:2.22
        pipeline-multibranch-defaults:1.1
        resource-disposer:0.6
        copy-to-slave:1.4.4
        workflow-step-api:2.14
        workflow-api:2.25
        workflow-support:2.18
        workflow-durable-task-step:2.18
        command-launcher:1.2
        build-token-root:1.4
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
        expect(chef_run).to create_jenkins_password_credentials('ibmz_ci')
      end
      it do
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
      end
      it 'should add docker images' do
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-s390x:16.04', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/debian-s390x:9', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/fedora-s390x:28', // image})
      end
      it 'should add docker hosts' do
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{tcp://192.168.0.1:2375})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{tcp://192.168.0.2:2375})
      end
      it do
        expect(chef_run).to execute_jenkins_script('Add GitHub OAuth config')
      end
      it do
        expect(chef_run).to run_ruby_block('Set jenkins username/password if needed')
      end
    end
  end
end
