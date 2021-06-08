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
          'oauth' => {
            'powerci' => {
              client_id: '123456789',
              client_secret: '0987654321',
            },
          },
          'git' => {
            'powerci' => {
              'user' => 'powerci',
              'token' => 'powerci',
            },
          }
        )
        stub_search('node', 'roles:powerci_docker').and_return(
          [
            {
              ipaddress: '192.168.0.1',
              fqdn: 'powerci-docker1.example.org',
            },
            {
              ipaddress: '192.168.0.2',
              fqdn: 'powerci-docker2.example.org',
            },
          ]
        )
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      %w(
        ansicolor:1.0.0
        build-monitor-plugin:1.12+build.201809061734
        build-timeout:1.20
        cloud-stats:0.27
        config-file-provider:3.8.0
        disable-github-multibranch-status:1.2
        docker-java-api:3.1.5.2
        docker-plugin:1.2.2
        email-ext:2.83
        emailext-template:1.2
        embeddable-build-status:2.0.3
        extended-read-permission:3.2
        job-restrictions:0.8
        jquery:1.12.4-1
        label-linked-jobs:6.0.1
        nodelabelparameter:1.8.1
        openstack-cloud:2.58
        pipeline-githubnotify-step:1.0.5
        pipeline-multibranch-defaults:2.1
        resource-disposer:0.15
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
        expect(chef_run).to install_jenkins_plugin('copy-to-slave').with(
          version: '1.4.4',
          install_deps: false,
          source: 'https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/copy-to-slave/1.4.4/copy-to-slave-1.4.4.hpi'
        )
      end
      it do
        expect(chef_run).to create_jenkins_password_credentials('powerci')
      end
      it do
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
      end
      it 'should add docker images' do
        %w(
          osuosl/ubuntu-ppc64le:16.04
          osuosl/ubuntu-ppc64le:18.04
          osuosl/ubuntu-ppc64le-cuda:8.0
          osuosl/ubuntu-ppc64le-cuda:9.0
          osuosl/ubuntu-ppc64le-cuda:9.1
          osuosl/ubuntu-ppc64le-cuda:9.2
          osuosl/ubuntu-ppc64le-cuda:10.0
          osuosl/ubuntu-ppc64le-cuda:8.0-cudnn6
          osuosl/ubuntu-ppc64le-cuda:9.0-cudnn7
          osuosl/ubuntu-ppc64le-cuda:9.1-cudnn7
          osuosl/ubuntu-ppc64le-cuda:9.2-cudnn7
          osuosl/ubuntu-ppc64le-cuda:10.0-cudnn7
          osuosl/debian-ppc64le:9
          osuosl/debian-ppc64le:buster
          osuosl/debian-ppc64le:unstable
          osuosl/fedora-ppc64le:28
          osuosl/fedora-ppc64le:29
          osuosl/centos-ppc64le:7
          osuosl/centos-ppc64le-cuda:8.0
          osuosl/centos-ppc64le-cuda:9.0
          osuosl/centos-ppc64le-cuda:9.1
          osuosl/centos-ppc64le-cuda:9.2
          osuosl/centos-ppc64le-cuda:8.0-cudnn6
          osuosl/centos-ppc64le-cuda:9.0-cudnn7
          osuosl/centos-ppc64le-cuda:9.1-cudnn7
          osuosl/centos-ppc64le-cuda:9.2-cudnn7
        ).each do |image|
          expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
            .with(command: /image: '#{image}',/)
          expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
            .with(command: /'docker-#{image.tr('\/:', '-')}-privileged',/)
        end
      end
      it 'should add docker hosts' do
        [
          %r{tcp://192.168.0.1:2375},
          %r{tcp://192.168.0.2:2375},
        ].each do |line|
          expect(chef_run).to execute_jenkins_script('Add Docker Cloud').with(command: line)
        end
      end
      it do
        [
          /String clientID = '123456789'/,
          /String clientSecret = '0987654321'/,
          /\["testadmin"\].each \{ au -> user = BuildPermission.*/,
          /\["testuser"\].each \{ nu -> user = BuildPermission.*/,
        ].each do |line|
          expect(chef_run).to execute_jenkins_script('Add GitHub OAuth config').with(command: line)
        end
      end
      # it do
      #   expect(chef_run).to execute_jenkins_script('Add OpenStack Cloud')
      # end
      it do
        expect(chef_run).to run_ruby_block('Set jenkins username/password if needed')
      end
    end
  end
end
