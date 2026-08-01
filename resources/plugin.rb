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

# jenkins-plugin-cli only ever adds plugins, so retired ones linger in the
# plugins dir until their files are removed. Only remove plugins nothing
# still depends on: the cli would reinstall a real dependency and a job
# config referencing a missing plugin fails to load.
action :remove do
  %W(
    /var/lib/jenkins/plugins/#{new_resource.plugin_name}.jpi
    /var/lib/jenkins/plugins/#{new_resource.plugin_name}.hpi
    /var/lib/jenkins/plugins/#{new_resource.plugin_name}.jpi.disabled
  ).each do |f|
    file f do
      action :delete
    end
  end

  directory "/var/lib/jenkins/plugins/#{new_resource.plugin_name}" do
    action :delete
    recursive true
  end
end
