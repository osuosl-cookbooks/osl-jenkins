require_relative '../../spec_helper'

describe 'osl-jenkins::plugins' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge('osl-jenkins::master', described_recipe)
      end
      include_context 'common_stubs'
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('/var/chef/cache/reload-jenkins').and_return(false)
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      it do
        expect(chef_run).to_not write_log('Safe Restart Jenkins').with(message: 'Safe Restart Jenkins')
      end
      it do
        expect(chef_run).to delete_file('/var/chef/cache/reload-jenkins')
      end
      it do
        expect(chef_run.notify_group('Safe Restart Jenkins Notify')).to notify('jenkins_command[safe-restart]').immediately
      end
      context 'installed new plugin' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(p).converge('osl-jenkins::master', described_recipe)
        end
        include_context 'common_stubs'
        before do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with('/var/chef/cache/reload-jenkins').and_return(true)
        end
        it do
          expect(chef_run).to write_log('Safe Restart Jenkins').with(message: 'Safe Restart Jenkins')
        end
      end
      %w(
        structs:1.20
        credentials:2.3.0
        ssh-credentials:1.18
      ).each do |plugins_version|
        plugin, version = plugins_version.split(':')
        it do
          expect(chef_run).to install_jenkins_plugin(plugin).with(
            version: version,
            install_deps: false
          )
        end
        it do
          expect(chef_run.jenkins_plugin(plugin)).to notify('jenkins_command[safe-restart]').to(:execute).immediately
        end
      end
      %w(
        ace-editor:1.1
        ant:1.8
        antisamy-markup-formatter:1.3
        apache-httpcomponents-client-4-api:4.5.10-2.0
        authentication-tokens:1.3
        authorize-project:1.3.0
        bouncycastle-api:2.16.3
        branch-api:2.0.8
        build-token-root:1.4
        cloudbees-folder:6.9
        command-launcher:1.2
        conditional-buildstep:1.3.1
        copyartifact:1.41
        credentials-binding:1.18
        cvs:2.12
        display-url-api:2.3.2
        docker-build-publish:1.3.2
        docker-commons:1.15
        docker-custom-build-environment:1.7.3
        docker-workflow:1.18
        durable-task:1.17
        external-monitor-job:1.4
        ghprb:1.42.0
        git:4.0.0
        git-client:3.0.0
        github:1.29.2
        github-api:1.90
        github-branch-source:2.3.6
        github-oauth:0.33
        github-organization-folder:1.6
        gitlab-plugin:1.5.13
        git-server:1.7
        handlebars:1.1.1
        icon-shim:2.0.3
        instant-messaging:1.38
        ircbot:2.31
        jackson2-api:2.9.8
        javadoc:1.3
        jquery-detached:1.2.1
        jsch:0.1.55.1
        junit:1.26.1
        ldap:1.12
        mailer:1.30
        mapdb-api:1.0.6.0
        matrix-auth:2.5
        matrix-project:1.14
        maven-plugin:3.4
        momentjs:1.1.1
        pam-auth:1.6
        parameterized-trigger:2.35.1
        pipeline-build-step:2.5.1
        pipeline-github-lib:1.0
        pipeline-graph-analysis:1.3
        pipeline-input-step:2.8
        pipeline-milestone-step:1.3.1
        pipeline-model-api:1.3.8
        pipeline-model-declarative-agent:1.1.1
        pipeline-model-definition:1.3.8
        pipeline-model-extensions:1.3.8
        pipeline-rest-api:2.6
        pipeline-stage-step:2.3
        pipeline-stage-tags-metadata:1.3.8
        pipeline-stage-view:2.6
        pipeline-utility-steps:1.4.0
        plain-credentials:1.4
        run-condition:1.0
        scm-api:2.6.3
        script-security:1.68
        ssh-agent:1.16
        ssh-slaves:1.28.1
        subversion:2.10.3
        text-finder:1.10
        token-macro:2.10
        translation:1.16
        trilead-api:1.0.5
        windows-slaves:1.1
        workflow-aggregator:2.5
        workflow-api:2.33
        workflow-basic-steps:2.6
        workflow-cps:2.71
        workflow-cps-global-lib:2.15
        workflow-durable-task-step:2.18
        workflow-job:2.26
        workflow-multibranch:2.16
        workflow-scm-step:2.9
        workflow-step-api:2.20
        workflow-support:3.3
        ws-cleanup:0.28
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
        it do
          expect(chef_run.jenkins_plugin(plugin)).to notify('file[/var/chef/cache/reload-jenkins]')
            .to(:touch).immediately
        end
      end
    end
  end
end
