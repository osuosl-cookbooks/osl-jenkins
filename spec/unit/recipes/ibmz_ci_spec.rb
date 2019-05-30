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
        cloud-stats:0.11
        command-launcher:1.2
        config-file-provider:3.6
        display-url-api:2.2.0
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
        job-restrictions:0.6
        jquery:1.12.4-0
        jsch:0.1.54.2
        junit:1.26.1
        label-linked-jobs:5.1.2
        mailer:1.21
        matrix-project:1.14
        nodelabelparameter:1.7.2
        pipeline-multibranch-defaults:1.1
        pipeline-stage-step:2.3
        resource-disposer:0.12
        scm-api:2.2.7
        script-security:1.56
        ssh-slaves:1.28.1
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
        expect(chef_run).to create_jenkins_password_credentials('ibmz_ci')
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
