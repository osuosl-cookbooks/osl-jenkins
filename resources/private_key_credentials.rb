resource_name :osl_jenkins_private_key_credentials
provides :osl_jenkins_private_key_credentials
unified_mode true
default_action :create

property :description, String, default: lazy { new_resource.name }
property :private_key, String, sensitive: true, required: true
property :scope, String, default: 'GLOBAL'
property :username, String, name_property: true

action :create do
  osl_jenkins_secret "private_key_credentials_private_key_#{new_resource.name}" do
    secret new_resource.private_key
  end

  osl_jenkins_config "private_key_credentials_#{new_resource.name}" do
    cookbook 'osl-jenkins'
    source 'private_key_credentials.yml.erb'
    variables(
      name: new_resource.name,
      scope: new_resource.scope,
      username: new_resource.username
    )
    sensitive true
  end
end
