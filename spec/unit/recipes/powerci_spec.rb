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
        config-file-provider:3.3
        copy-to-slave:1.4.4
        credentials:2.1.17
        display-url-api:2.2.0
        docker-build-publish:1.3.2
        docker-commons:1.11
        docker-java-api:3.0.14
        docker-plugin:1.1.3
        durable-task:1.17
        email-ext:2.62
        emailext-template:1.1
        embeddable-build-status:1.9
        git-client:2.7.1
        git:3.9.1
        github-api:1.90
        github-branch-source:2.3.6
        github-oauth:0.27
        github:1.29.2
        job-restrictions:0.6
        jsch:0.1.54.2
        junit:1.26.1
        mailer:1.21
        matrix-project:1.13
        openstack-cloud:2.37
        pipeline-multibranch-defaults:1.1
        resource-disposer:0.12
        ssh-slaves:1.28.1
        structs:1.14
        workflow-api:2.25
        workflow-durable-task-step:2.18
        workflow-job:2.11
        workflow-step-api:2.16
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
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le:16.04', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le:18.04', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le-cuda:8.0', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le-cuda:8.0-cudnn6', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le-cuda:9.0-cudnn7', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le-cuda:9.1-cudnn7', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/ubuntu-ppc64le-cuda:9.2-cudnn7', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/debian-ppc64le:9', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/debian-ppc64le:buster', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/debian-ppc64le:unstable', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/fedora-ppc64le:26', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/fedora-ppc64le:27', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/fedora-ppc64le:28', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/centos-ppc64le:7', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/centos-ppc64le-cuda:8.0', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/centos-ppc64le-cuda:8.0-cudnn6', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/centos-ppc64le-cuda:9.0-cudnn7', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/centos-ppc64le-cuda:9.1-cudnn7', // image})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{'osuosl/centos-ppc64le-cuda:9.2-cudnn7', // image})
      end
      it 'should add docker hosts' do
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{tcp://192.168.0.1:2375})
        expect(chef_run).to execute_jenkins_script('Add Docker Cloud')
          .with(command: %r{tcp://192.168.0.2:2375})
      end
      it do
        expect(chef_run).to execute_jenkins_script('Add GitHub OAuth config')
          .with(command: /String clientID = '123456789'/)
        expect(chef_run).to execute_jenkins_script('Add GitHub OAuth config')
          .with(command: /String clientSecret = '0987654321'/)
        expect(chef_run).to execute_jenkins_script('Add GitHub OAuth config')
          .with(command: /\["testadmin"\].each \{ au -> user = BuildPermission.*/)
        expect(chef_run).to execute_jenkins_script('Add GitHub OAuth config')
          .with(command: /\["testuser"\].each \{ nu -> user = BuildPermission.*/)
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
      it 'Add SGE Cloud: cuda91' do
        expect(chef_run).to execute_jenkins_script('Add SGE Cloud')
          .with(
            command: %r{
BatchCloud sge_CGRB_ubuntu_cuda91 = new BatchCloud\(
  'CGRB-ubuntu-cuda91',    // cloudName
  'docker_gpu@openpower3',   // queueType
  'docker-gpu-cuda91',   // label
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
