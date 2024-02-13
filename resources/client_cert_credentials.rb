resource_name :osl_jenkins_client_cert_credentials
provides :osl_jenkins_client_cert_credentials
unified_mode true
default_action :create

property :cert, String, required: true
property :chain, String
property :description, String, default: lazy { name }
property :key, String, sensitive: true, required: true
property :scope, String, default: 'GLOBAL'

action :create do
  osl_jenkins_secret "client_cert_credentials_cert_#{new_resource.name}" do
    secret new_resource.cert
  end

  osl_jenkins_secret "client_cert_credentials_key_#{new_resource.name}" do
    secret new_resource.key
  end

  osl_jenkins_secret "client_cert_credentials_chain_#{new_resource.name}" do
    secret new_resource.chain
  end if new_resource.chain

  osl_jenkins_config "client_cert_credentials_#{new_resource.name}" do
    cookbook 'osl-jenkins'
    source 'client_cert_credentials.yml.erb'
    variables(
      description: new_resource.description,
      name: new_resource.name,
      scope: new_resource.scope
    )
    sensitive true
  end
end
