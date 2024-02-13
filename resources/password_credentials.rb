resource_name :osl_jenkins_password_credentials
provides :osl_jenkins_password_credentials
unified_mode true
default_action :create

property :password, String, sensitive: true, required: true
property :scope, String, default: 'GLOBAL'
property :username, String, name_property: true

action :create do
  osl_jenkins_secret "password_credentials_username_#{new_resource.name}" do
    secret new_resource.username
  end

  osl_jenkins_secret "password_credentials_password_#{new_resource.name}" do
    secret new_resource.password
  end

  osl_jenkins_config "password_credentials_#{new_resource.name}" do
    cookbook 'osl-jenkins'
    source 'password_credentials.yml.erb'
    variables(
      name: new_resource.name,
      scope: new_resource.scope
    )
    sensitive true
  end
end
