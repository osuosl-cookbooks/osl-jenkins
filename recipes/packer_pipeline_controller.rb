#
# Cookbook:: osl-jenkins
# Recipe:: packer_pipeline
#
# Copyright:: 2015-2022, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Installs necessary gems

%w(git octokit faraday-http-cache).each do |p|
  chef_gem p do
    compile_time true
  end
end

# Sets up the controller for packer_pipeline

include_recipe 'osl-jenkins::controller'

# get attributes specific to this job
bin_path = node['osl-jenkins']['bin_path']
lib_path = node['osl-jenkins']['lib_path']

cookbook_file ::File.join(bin_path, 'packer_pipeline.rb') do
  source 'bin/packer_pipeline.rb'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode '550'
end

cookbook_file ::File.join(lib_path, 'packer_pipeline.rb') do
  source 'lib/packer_pipeline.rb'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode '440'
end

# define the path where the packer_pipeline job's xml would be temporarily cached on the machine
packer_pipeline_xml = ::File.join(Chef::Config[:file_cache_path], 'packer_pipeline', 'config.xml')
secrets = credential_secrets
jenkins_credentials = secrets['jenkins']['packer_pipeline']

directory ::File.dirname(packer_pipeline_xml) do
  recursive true
end

template packer_pipeline_xml do
  source 'packer_pipeline.config.xml.erb'
  mode '440'
  variables(
    trigger_token: jenkins_credentials['trigger_token']
  )
end

# this actually takes care of putting the config.xml for the job in the jenkins dir
# this config.xml does *NOT* contain the actual Groovy Script which is the heart of the job.
# the groovy script will be a fresh version checked out from the packer-templates repo everytime.
jenkins_job 'packer_pipeline' do
  config packer_pipeline_xml
  action :create
end
