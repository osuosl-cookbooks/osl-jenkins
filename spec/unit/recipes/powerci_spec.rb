require_relative '../../spec_helper'

describe 'osl-jenkins::powerci' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common_stubs'
      before do
        allow(Chef::EncryptedDataBagItem).to receive(:load).with('osl_jenkins', 'powerci').and_return(
          admin_users: ['testadmin'],
          normal_users: ['testuser'],
          'oauth' => {
            'powerci' => {
              client_id: '123456789',
              client_secret: '0987654321'
            }
          },
          'git' => {
            'powerci' => {
              'user' => 'powerci',
              'token' => 'powerci'
            }
          }
        )
        stub_search('node', 'roles:powerci_docker').and_return(
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
        apache-httpcomponents-client-4-api:4.5.3-2.1
        build-monitor-plugin:1.11+build.201701152243
        cloud-stats:0.11
        config-file-provider:2.16.2
        copy-to-slave:1.4.4
        credentials:2.1.16
        docker-build-publish:1.3.2
        docker-commons:1.8
        docker-plugin:0.16.2
        durable-task:1.17
        email-ext:2.57.2
        emailext-template:1.0
        embeddable-build-status:1.9
        git:3.8.0
        git-client:2.7.1
        github-api:1.90
        github-oauth:0.27
        job-restrictions:0.6
        jsch:0.1.54.2
        matrix-project:1.10
        openstack-cloud:2.22
        pipeline-multibranch-defaults:1.1
        resource-disposer:0.6
        structs:1.14
        workflow-api:2.25
        workflow-durable-task-step:2.18
        command-launcher:1.2
        build-token-root:1.4
        workflow-step-api:2.14
        workflow-support:2.18
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
        expect(chef_run).to install_jenkins_plugin('sge-cloud-plugin').with(
          version: '1.17',
          install_deps: false,
          source: 'http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/sge-cloud-plugin/' \
                  '1.17/sge-cloud-plugin-1.17.hpi'
        )
      end
      it do
        expect(chef_run.jenkins_plugin('sge-cloud-plugin')).to notify('jenkins_command[safe-restart]')
      end
      it do
        expect(chef_run).to create_jenkins_password_credentials('powerci')
      end
      it do
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
      end
      it 'should add docker images' do
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le:16.04', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le-cuda:8.0', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le-cuda:8.0-cudnn6', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le-cuda:9.0-cudnn7', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le-cuda:9.1-cudnn7', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/debian-ppc64le:9', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/fedora-ppc64le:26', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/centos-ppc64le:7', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/centos-ppc64le-cuda:8.0', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/centos-ppc64le-cuda:8.0-cudnn6', // image})
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
        expect(chef_run).to execute_jenkins_script('Add OpenStack Cloud')
      end
      it do
        expect(chef_run).to run_ruby_block('Set jenkins username/password if needed')
      end
    end
  end
end
