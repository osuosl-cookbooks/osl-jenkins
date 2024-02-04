require_relative '../../spec_helper'

describe 'osl-jenkins::ibmz_ci' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common_stubs'
      before do
        stub_data_bag_item('osl_jenkins', 'ibmz_ci').and_return(
          admin_users: ['testadmin'],
          normal_users: ['testuser'],
          'oauth' => {
            'ibmz_ci' => {
              client_id: '123456789',
              client_secret: '0987654321',
            },
          },
          'git' => {
            'ibmz_ci' => {
              'user' => 'ibmz_ci',
              'token' => 'ibmz_ci',
            },
          }
        )
        stub_data_bag_item('docker', 'client-fauxhai-local').and_return(
          key: 'key',
          cert: 'cert',
          chain: 'chain'
        )
        stub_search('node', 'roles:ibmz_ci_docker').and_return(
          [
            {
              ipaddress: '192.168.0.1',
              fqdn: 's390x-docker1.example.org',
            },
            {
              ipaddress: '192.168.0.2',
              fqdn: 's390x-docker2.example.org',
            },
          ]
        )
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      #       %w(
      #         ansicolor:1.0.0
      #         build-monitor-plugin:1.12+build.201809061734
      #         build-timeout:1.20
      #         cloud-stats:0.27
      #         config-file-provider:3.8.0
      #         disable-github-multibranch-status:1.2
      #         docker-java-api:3.1.5.2
      #         docker-plugin:1.2.2
      #         email-ext:2.83
      #         emailext-template:1.2
      #         embeddable-build-status:2.0.3
      #         extended-read-permission:3.2
      #         job-restrictions:0.8
      #         jquery:1.12.4-1
      #         label-linked-jobs:6.0.1
      #         nodelabelparameter:1.8.1
      #         pipeline-githubnotify-step:1.0.5
      #         pipeline-multibranch-defaults:2.1
      #         resource-disposer:0.15
      #       ).each do |plugins_version|
      #         plugin, version = plugins_version.split(':')
      #         it do
      #           expect(chef_run).to install_jenkins_plugin(plugin).with(
      #             version: version,
      #             install_deps: false
      #           )
      #         end
      #         it do
      #           expect(chef_run.jenkins_plugin(plugin)).to notify('jenkins_command[safe-restart]')
      #         end
      #       end
      #       it do
      #         expect(chef_run).to create_jenkins_password_credentials('ibmz_ci')
      #       end
      it do
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
      end
      it 'should add docker images' do
        %w(
          osuosl/ubuntu-s390x:16.04
          osuosl/ubuntu-s390x:18.04
          osuosl/debian-s390x:9
          osuosl/debian-s390x:buster
          osuosl/debian-s390x:unstable
          osuosl/fedora-s390x:28
          osuosl/fedora-s390x:29
        ).each do |image|
          expect(chef_run).to execute_jenkins_script('Add Docker Cloud').with(command: /image: '#{image}'/)
          expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
            .with(command: %r{'docker-#{image.tr('/:', '-')}-privileged', // labelString})
        end
      end
      it 'should add docker hosts' do
        [
          %r{tcp://192.168.0.1:2376.*\n.*ibmz_ci_docker-server.*},
          %r{tcp://192.168.0.2:2376.*\n.*ibmz_ci_docker-server.*},
        ].each do |line|
          expect(chef_run).to execute_jenkins_script('Add Docker Cloud').with(command: line)
        end
      end
      it do
        [
          /String clientSecret = '0987654321'/,
          /\["testadmin"\].each \{ au -> user = BuildPermission.*/,
          /\["testuser"\].each \{ nu -> user = BuildPermission.*/,
        ].each do |line|
          expect(chef_run).to execute_jenkins_script('Add GitHub OAuth config').with(command: line)
        end
      end
      it do
        expect(chef_run).to run_ruby_block('Set jenkins username/password if needed')
      end
    end
  end
end
