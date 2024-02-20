module OslJenkins
  module Cookbook
    module ResourceHelpers
      def osl_jenkins_plugin_resource_init
        osl_jenkins_plugin_resource_create unless osl_jenkins_plugin_resource_exist?
      end

      def osl_jenkins_plugin_resource
        return unless osl_jenkins_plugin_resource_exist?

        find_resource!(:template, new_resource.plugin_file)
      end

      private

      def osl_jenkins_plugin_resource_exist?
        !find_resource!(:template, new_resource.plugin_file).nil?
      rescue Chef::Exceptions::ResourceNotFound
        false
      end

      def osl_jenkins_plugin_resource_create
        with_run_context(:root) do
          declare_resource(:directory, ::File.dirname(new_resource.plugin_file)) do
            owner 'jenkins'
            group 'jenkins'
            recursive true

            action :create
          end

          declare_resource(:template, new_resource.plugin_file) do
            cookbook 'osl-jenkins'
            source 'plugins.txt.erb'
            owner 'jenkins'
            group 'jenkins'

            helpers(OslJenkins::Cookbook::TemplateHelpers)

            action :nothing
            delayed_action :create
            notifies :run, 'execute[jenkins-plugin-cli]', :immediately
          end

          declare_resource(:execute, 'jenkins-plugin-cli') do
            command '/usr/local/bin/jenkins-plugin-cli --plugin-file /var/lib/jenkins/plugins.txt'
            user 'jenkins'
            group 'jenkins'

            action :nothing
            delayed_action :nothing
          end
        end
      end
    end
  end
end
