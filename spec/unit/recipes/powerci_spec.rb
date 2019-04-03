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
          'sge' => {
            username: 'username',
            password: 'password',
            hostname: 'sge.example.org',
            port: 22,
          },
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
        ansicolor:0.5.2
        apache-httpcomponents-client-4-api:4.5.5-3.0
        bouncycastle-api:2.16.3
        build-monitor-plugin:1.11+build.201701152243
        build-timeout:1.19
        build-token-root:1.4
        cloud-stats:0.14
        command-launcher:1.2
        config-file-provider:3.6
        copy-to-slave:1.4.4
        credentials:2.1.17
        display-url-api:2.2.0
        docker-build-publish:1.3.2
        docker-commons:1.11
        docker-java-api:3.0.14
        docker-plugin:1.1.3
        durable-task:1.17
        email-ext:2.66
        emailext-template:1.1
        embeddable-build-status:1.9
        git:3.9.3
        git-client:2.7.1
        github:1.29.2
        github-api:1.90
        github-branch-source:2.3.6
        github-oauth:0.31
        jackson2-api:2.8.11.2
        job-restrictions:0.6
        jquery:1.12.4-0
        jsch:0.1.54.2
        junit:1.26.1
        label-linked-jobs:5.1.2
        mailer:1.21
        matrix-project:1.14
        nodelabelparameter:1.7.2
        openstack-cloud:2.37
        pipeline-model-api:1.3.4.1
        pipeline-model-definition:1.3.4.1
        pipeline-model-extensions:1.3.4.1
        pipeline-multibranch-defaults:1.1
        pipeline-stage-step:2.3
        pipeline-stage-tags-metadata:1.3.4.1
        resource-disposer:0.12
        scm-api:2.2.7
        script-security:1.56
        ssh-slaves:1.28.1
        structs:1.17
        token-macro:2.7
        workflow-api:2.30
        workflow-basic-steps:2.6
        workflow-cps:2.65
        workflow-cps-global-lib:2.9
        workflow-durable-task-step:2.18
        workflow-job:2.26
        workflow-multibranch:2.16
        workflow-scm-step:2.6
        workflow-step-api:2.19
        workflow-support:3.2
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
          source: 'http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/copy-to-slave/' \
                  '1.4.4/copy-to-slave-1.4.4.hpi'
        )
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
            .with(command: %r{'#{image}', // image})
          expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
            .with(command: %r{'docker-#{image.tr('/:', '-')}-privileged', // labelString})
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
      it 'Add SGE Cloud: default' do
        expect(chef_run).to execute_jenkins_script('Add SGE Cloud')
          .with(
            command: %r{
BatchCloud sge_CGRB_ubuntu = new BatchCloud\(
  'CGRB-ubuntu',    // cloudName
  'docker_gpu',   // queueType
  'docker-gpu',   // label
  1440,         // maximumIdleMinutes
  'sge.example.org', // hostname
  22,      // port
  'username', // username
  'password' // password
\)}

          )
      end
      it 'Add SGE Cloud: cuda92' do
        expect(chef_run).to execute_jenkins_script('Add SGE Cloud')
          .with(
            command: %r{
BatchCloud sge_CGRB_ubuntu_cuda92 = new BatchCloud\(
  'CGRB-ubuntu-cuda92',    // cloudName
  'docker_gpu@openpower2',   // queueType
  'docker-gpu-cuda92',   // label
  1440,         // maximumIdleMinutes
  'sge.example.org', // hostname
  22,      // port
  'username', // username
  'password' // password
\)}

          )
      end
      it do
        expect(chef_run).to run_ruby_block('Set jenkins username/password if needed')
      end
    end
  end
end
