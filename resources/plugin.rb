resource_name :osl_jenkins_plugin
provides :osl_jenkins_plugin
unified_mode true
default_action :install

property :plugin_file, String, default: '/var/lib/jenkins/plugins.txt'
property :plugin_name, String, name_property: true
property :plugin_version, String, default: 'latest'

action_class do
  include OslJenkins::Cookbook::ResourceHelpers
end

action :install do
  osl_jenkins_plugin_resource_init
  osl_jenkins_plugin_resource.variables['plugins'] ||= {}
  osl_jenkins_plugin_resource.variables['plugins'][new_resource.plugin_name] ||= {}
  osl_jenkins_plugin_resource.variables['plugins'][new_resource.plugin_name]['version'] = new_resource.plugin_version
end
