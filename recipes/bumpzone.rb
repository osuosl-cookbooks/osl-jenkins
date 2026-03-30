#
# Cookbook:: osl-jenkins
# Recipe:: bumpzone
#
# Copyright:: 2017-2026, Oregon State University
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
chef_gem 'faraday-http-cache' do
  version '< 2.6'
  compile_time true
end

chef_gem 'git' do
  version '< 4'
  compile_time true
end

chef_gem 'octokit' do
  version '< 10'
  compile_time true
end

bumpzone = node['osl-jenkins']['bumpzone']
secrets = credential_secrets
jenkins_cred = secrets['jenkins']['bumpzone']

cookbook_file ::File.join(osl_jenkins_lib_path, 'yajl_workaround.rb') do
  source 'lib/yajl_workaround.rb'
  owner 'jenkins'
  group 'jenkins'
  mode '440'
end

%w(bumpzone.rb checkzone.rb).each do |f|
  cookbook_file ::File.join(osl_jenkins_bin_path, f) do
    source "bin/#{f}"
    owner 'jenkins'
    group 'jenkins'
    mode '550'
  end

  cookbook_file ::File.join(osl_jenkins_lib_path, f) do
    source "lib/#{f}"
    owner 'jenkins'
    group 'jenkins'
    mode '440'
  end
end

package 'bind'

osl_jenkins_service 'bumpzone' do
  action :nothing
end

osl_jenkins_plugin 'slack' do
  notifies :restart, 'osl_jenkins_service[bumpzone]', :delayed
end

osl_jenkins_job 'bumpzone' do
  source 'jobs/bumpzone.groovy.erb'
  template true
  variables(
    github_url: bumpzone['github_url'],
    trigger_token: jenkins_cred['trigger_token']
  )
  sensitive true
  notifies :restart, 'osl_jenkins_service[bumpzone]', :delayed
end

osl_jenkins_job 'checkzone' do
  source 'jobs/checkzone.groovy.erb'
  template true
  variables(
    github_url: bumpzone['github_url'],
    trigger_token: jenkins_cred['trigger_token']
  )
  sensitive true
  notifies :restart, 'osl_jenkins_service[bumpzone]', :delayed
end

osl_jenkins_job 'update-zonefiles' do
  source 'jobs/update-zonefiles.groovy.erb'
  template true
  variables(
    github_url: bumpzone['github_url'],
    dns_primary: bumpzone['dns_primary']
  )
  notifies :restart, 'osl_jenkins_service[bumpzone]', :delayed
end
