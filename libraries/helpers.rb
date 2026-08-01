module OslJenkins
  module Cookbook
    module Helpers
      def osl_jenkins_bin_path
        '/var/lib/jenkins/bin'
      end

      def osl_jenkins_lib_path
        '/var/lib/jenkins/lib'
      end

      def osl_jenkins_java_version
        '21'
      end

      # Deprecated plugins Jenkins flags on the dashboard: hand-installed
      # relics and former dependencies that current plugin versions no longer
      # pull in. None are in the managed plugin set, so they only linger as
      # leftover files until removed. Before adding a controller or a plugin
      # here, verify nothing depends on or uses it (preflight-check.groovy).
      def osl_jenkins_deprecated_plugins
        %w(
          ace-editor
          bootstrap4-api
          copy-to-slave
          ghprb
          github-organization-folder
          handlebars
          icon-shim
          jquery-detached
          momentjs
          pipeline-model-declarative-agent
          popper-api
          popper2-api
          translation
          windows-slaves
          workflow-cps-global-lib
        )
      end

      def osl_jenkins_default_plugins
        %w(
          antisamy-markup-formatter
          cloudbees-folder
          conditional-buildstep
          configuration-as-code
          copyartifact
          csp
          credentials-binding
          dark-theme
          email-ext
          embeddable-build-status
          git
          github
          github-checks
          gitlab-plugin
          github-pullrequest
          git-parameter
          ircbot
          job-dsl
          ldap
          mailer
          matrix-auth
          matrix-project
          pam-auth
          parameterized-trigger
          pipeline-github
          pipeline-github-lib
          pipeline-model-definition
          pipeline-stage-view
          ssh-agent
          ssh-credentials
          ssh-slaves
          text-finder
          timestamper
          workflow-aggregator
          ws-cleanup
        )
      end
    end
  end
end
Chef::DSL::Recipe.include ::OslJenkins::Cookbook::Helpers
Chef::Resource.include ::OslJenkins::Cookbook::Helpers
