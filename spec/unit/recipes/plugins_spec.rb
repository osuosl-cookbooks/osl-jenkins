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
          expect(chef_run.notify_group('Safe Restart Jenkins Notify')).to notify('jenkins_command[safe-restart]').immediately
        end
      end
      %w(
        structs:1.20
        credentials:2.3.14
        ssh-credentials:1.18.1
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
        ant:1.11
        antisamy-markup-formatter:2.1
        apache-httpcomponents-client-4-api:4.5.13-1.0
        authentication-tokens:1.4
        authorize-project:1.3.0
        bootstrap4-api:4.5.3-2
        bouncycastle-api:2.18
        branch-api:2.6.2
        build-token-root:1.7
        cloudbees-folder:6.15
        command-launcher:1.5
        conditional-buildstep:1.4.1
        copyartifact:1.46
        checks-api:1.2.0
        credentials-binding:1.24
        cvs:2.17
        display-url-api:2.3.4
        docker-build-publish:1.3.2
        docker-commons:1.17
        docker-custom-build-environment:1.7.3
        docker-workflow:1.25
        durable-task:1.35
        echarts-api:4.9.0-3
        external-monitor-job:1.7
        font-awesome-api:5.15.1-1
        ghprb:1.42.1
        git:4.5.2
        git-client:3.6.0
        github:1.32.0
        github-api:1.122
        github-branch-source:2.9.3
        github-oauth:0.33
        github-organization-folder:1.6
        gitlab-plugin:1.5.13
        git-server:1.9
        handlebars:1.1.1
        icon-shim:2.0.3
        instant-messaging:1.39
        ircbot:2.33
        jackson2-api:2.12.1
        javadoc:1.6
        jdk-tool:1.4
        jquery-detached:1.2.1
        jquery3-api:3.5.1-2
        jsch:0.1.55.2
        junit:1.48
        ldap:1.26
        lockable-resources:2.10
        mailer:1.32.1
        mapdb-api:1.0.9.0
        matrix-auth:2.6.5
        matrix-project:1.18
        maven-plugin:3.8
        momentjs:1.1.1
        okhttp-api:3.14.9
        pam-auth:1.6
        parameterized-trigger:2.39
        pipeline-build-step:2.13
        pipeline-github-lib:1.0
        pipeline-graph-analysis:1.10
        pipeline-input-step:2.12
        pipeline-milestone-step:1.3.1
        pipeline-model-api:1.7.2
        pipeline-model-declarative-agent:1.1.1
        pipeline-model-definition:1.7.2
        pipeline-model-extensions:1.7.2
        pipeline-rest-api:2.19
        pipeline-stage-step:2.5
        pipeline-stage-tags-metadata:1.7.2
        pipeline-stage-view:2.19
        pipeline-utility-steps:2.6.1
        plain-credentials:1.7
        plugin-util-api:1.6.1
        popper-api:1.16.0-7
        resource-disposer:0.14
        run-condition:1.5
        scm-api:2.6.4
        script-security:1.75
        snakeyaml-api:1.27.0
        ssh-agent:1.20
        ssh-slaves:1.31.5
        subversion:2.14.0
        text-finder:1.15
        token-macro:2.13
        translation:1.16
        trilead-api:1.0.13
        windows-slaves:1.7
        workflow-aggregator:2.6
        workflow-api:2.41
        workflow-basic-steps:2.23
        workflow-cps:2.87
        workflow-cps-global-lib:2.17
        workflow-durable-task-step:2.37
        workflow-job:2.40
        workflow-multibranch:2.22
        workflow-scm-step:2.11
        workflow-step-api:2.23
        workflow-support:3.7
        ws-cleanup:0.38
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
