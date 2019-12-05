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
      %w(
        ansicolor:0.5.2
        apache-httpcomponents-client-4-api:4.5.10-2.0
        authorize-project:1.3.0
        bouncycastle-api:2.16.3
        build-monitor-plugin:1.11+build.201701152243
        build-timeout:1.19
        build-token-root:1.4
        cloudbees-folder:6.9
        cloud-stats:0.11
        command-launcher:1.2
        config-file-provider:3.6
        display-url-api:2.2.0
        docker-java-api:3.0.14
        docker-plugin:1.1.9
        durable-task:1.17
        email-ext:2.66
        emailext-template:1.1
        embeddable-build-status:2.0.3
        git:3.9.3
        git-client:3.0.0
        github:1.29.2
        github-api:1.90
        github-branch-source:2.3.6
        github-oauth:0.33
        gitlab-plugin:1.5.13
        instant-messaging:1.38
        ircbot:2.31
        job-restrictions:0.6
        jquery:1.12.4-0
        jsch:0.1.55.1
        junit:1.26.1
        label-linked-jobs:5.1.2
        mailer:1.21
        matrix-auth:2.5
        matrix-project:1.14
        maven-plugin:3.4
        nodelabelparameter:1.7.2
        pam-auth:1.6
        pipeline-multibranch-defaults:1.1
        pipeline-stage-step:2.3
        resource-disposer:0.12
        scm-api:2.6.3
        script-security:1.68
        ssh-slaves:1.28.1
        token-macro:2.10
        trilead-api:1.0.5
        workflow-api:2.33
        workflow-basic-steps:2.6
        workflow-cps:2.71
        workflow-cps-global-lib:2.15
        workflow-durable-task-step:2.18
        workflow-job:2.26
        workflow-multibranch:2.16
        workflow-scm-step:2.7
        workflow-step-api:2.20
        workflow-support:3.3
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
        %w(
          osuosl/ubuntu-s390x:16.04
          osuosl/ubuntu-s390x:18.04
          osuosl/debian-s390x:9
          osuosl/debian-s390x:buster
          osuosl/debian-s390x:unstable
          osuosl/fedora-s390x:28
          osuosl/fedora-s390x:29
        ).each do |image|
          expect(chef_run).to execute_jenkins_script('Add Docker Cloud').with(command: %r{'#{image}', // image})
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
