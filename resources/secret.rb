resource_name :osl_jenkins_secret
provides :osl_jenkins_secret
unified_mode true
default_action :create

property :secret, String, required: true, sensitive: true

action :create do
  file "/var/lib/jenkins/casc_configs/secrets/#{new_resource.name}" do
    content new_resource.secret
    sensitive true
    owner 'jenkins'
    group 'jenkins'
    mode '0400'
  end
end
