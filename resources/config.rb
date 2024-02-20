resource_name :osl_jenkins_config
provides :osl_jenkins_config
unified_mode true
default_action :create

property :cookbook, String
property :source, String
property :variables, Hash, default: {}

action :create do
  template "/var/lib/jenkins/casc_configs/#{new_resource.name}.yml" do
    cookbook new_resource.cookbook if new_resource.cookbook
    source new_resource.source if new_resource.source
    variables new_resource.variables
    sensitive new_resource.sensitive
    owner 'jenkins'
    group 'jenkins'
    mode '0400'
  end
end
