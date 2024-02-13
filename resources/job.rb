resource_name :osl_jenkins_job
provides :osl_jenkins_job
unified_mode true
default_action :create

property :cookbook, String
property :file, [true, false]
property :script, String
property :source, String
property :template, [true, false]
property :variables, Hash, default: {}

action :create do
  cookbook_file "/var/lib/jenkins/casc_configs/groovy/job_#{new_resource.name}.groovy" do
    source new_resource.source if new_resource.source
    cookbook new_resource.cookbook if new_resource.cookbook
    sensitive new_resource.sensitive
    owner 'jenkins'
    group 'jenkins'
    mode '0400'
  end if new_resource.file

  template "/var/lib/jenkins/casc_configs/groovy/job_#{new_resource.name}.groovy" do
    source new_resource.source if new_resource.source
    variables new_resource.variables
    cookbook new_resource.cookbook if new_resource.cookbook
    sensitive new_resource.sensitive
    owner 'jenkins'
    group 'jenkins'
    mode '0400'
  end if new_resource.template

  template "/var/lib/jenkins/casc_configs/job_#{new_resource.name}.yml" do
    cookbook 'osl-jenkins'
    source 'job.yml.erb'
    variables(
      file: new_resource.file,
      name: new_resource.name,
      script: new_resource.script,
      template: new_resource.template
    )
    sensitive new_resource.sensitive
    owner 'jenkins'
    group 'jenkins'
    mode '0400'
  end
end

action :delete do
  file "/var/lib/jenkins/casc_configs/groovy/job_#{new_resource.name}.groovy" do
    sensitive new_resource.sensitive
    action :delete
  end if new_resource.file || new_resource.template

  file "/var/lib/jenkins/casc_configs/job_#{new_resource.name}.yml" do
    sensitive new_resource.sensitive
    action :delete
  end
end
