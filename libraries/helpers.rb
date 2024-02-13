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
        case node['platform_version'].to_i
        when 7
          '11'
        when 8
          'latest'
        end
      end

      def osl_jenkins_default_plugins
        %w(
          antisamy-markup-formatter
          cloudbees-folder
          conditional-buildstep
          configuration-as-code
          copyartifact
          credentials-binding
          dark-theme
          email-ext
          embeddable-build-status
          git
          github
          gitlab-plugin
          git-parameter
          ircbot
          job-dsl
          ldap
          mailer
          matrix-auth
          matrix-project
          pam-auth
          parameterized-trigger
          pipeline-github-lib
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
