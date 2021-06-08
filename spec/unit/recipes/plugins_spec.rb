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
      # To generate this list, import the the following code into https://<ip address>/script and run it.
      #
      # Jenkins.instance.pluginManager.plugins.each{
      #   plugin ->
      #     println ("${plugin.getShortName()}:${plugin.getVersion()}")
      # }
      %w(
        structs:1.23
        credentials:2.5
        ssh-credentials:1.19
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
        authorize-project:1.4.0
        bootstrap4-api:4.6.0-3
        bouncycastle-api:2.20
        branch-api:2.6.4
        build-token-root:1.7
        caffeine-api:2.9.1-23.v51c4e2c879c8
        checks-api:1.7.0
        cloudbees-folder:6.15
        command-launcher:1.6
        conditional-buildstep:1.4.1
        copyartifact:1.46.1
        credentials-binding:1.25
        cvs:2.19
        display-url-api:2.3.5
        docker-build-publish:1.3.3
        docker-commons:1.17
        docker-custom-build-environment:1.7.3
        docker-workflow:1.26
        durable-task:1.37
        echarts-api:5.1.0-2
        external-monitor-job:1.7
        font-awesome-api:5.15.3-2
        ghprb:1.42.2
        git:4.7.2
        git-client:3.7.2
        github:1.33.1
        github-api:1.123
        github-branch-source:2.11.1
        github-oauth:0.33
        github-organization-folder:1.6
        gitlab-plugin:1.5.20
        git-server:1.9
        handlebars:3.0.8
        icon-shim:3.0.0
        instant-messaging:1.42
        ircbot:2.36
        jackson2-api:2.12.3
        javadoc:1.6
        jdk-tool:1.5
        jjwt-api:0.11.2-9.c8b45b8bb173
        jquery3-api:3.6.0-1
        jquery-detached:1.2.1
        jsch:0.1.55.2
        junit:1.50
        ldap:2.7
        lockable-resources:2.11
        mailer:1.34
        mapdb-api:1.0.9.0
        matrix-auth:2.6.7
        matrix-project:1.19
        maven-plugin:3.11
        momentjs:1.1.1
        okhttp-api:3.14.9
        pam-auth:1.6
        parameterized-trigger:2.40
        pipeline-build-step:2.13
        pipeline-github-lib:1.0
        pipeline-graph-analysis:1.11
        pipeline-input-step:2.12
        pipeline-milestone-step:1.3.2
        pipeline-model-api:1.8.5
        pipeline-model-declarative-agent:1.1.1
        pipeline-model-definition:1.8.5
        pipeline-model-extensions:1.8.5
        pipeline-rest-api:2.19
        pipeline-stage-step:2.5
        pipeline-stage-tags-metadata:1.8.5
        pipeline-stage-view:2.19
        pipeline-utility-steps:2.8.0
        plain-credentials:1.7
        plugin-util-api:2.2.0
        popper-api:1.16.1-2
        resource-disposer:0.15
        run-condition:1.5
        scm-api:2.6.4
        script-security:1.77
        snakeyaml-api:1.27.0
        ssh-agent:1.22
        sshd:3.0.3
        ssh-slaves:1.32.0
        subversion:2.14.2
        text-finder:1.16
        token-macro:2.15
        translation:1.16
        trilead-api:1.0.13
        windows-slaves:1.8
        workflow-aggregator:2.6
        workflow-api:2.44
        workflow-basic-steps:2.23
        workflow-cps:2.92
        workflow-cps-global-lib:2.19
        workflow-durable-task-step:2.39
        workflow-job:2.41
        workflow-multibranch:2.24
        workflow-scm-step:2.12
        workflow-step-api:2.23
        workflow-support:3.8
        ws-cleanup:0.39
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
