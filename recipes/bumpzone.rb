#
# Cookbook:: osl-jenkins
# Recipe:: bumpzone
#
# Copyright:: 2017-2021, Oregon State University
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
%w(git octokit faraday-http-cache).each do |p|
  chef_gem p do
    compile_time true
  end
end
include_recipe 'osl-jenkins::master'

bumpzone = node['osl-jenkins']['bumpzone']
bin_path = node['osl-jenkins']['bin_path']
lib_path = node['osl-jenkins']['lib_path']

%w(bumpzone.rb checkzone.rb).each do |f|
  cookbook_file ::File.join(bin_path, f) do
    source "bin/#{f}"
    owner node['jenkins']['master']['user']
    group node['jenkins']['master']['group']
    mode '550'
  end

  cookbook_file ::File.join(lib_path, f) do
    source "lib/#{f}"
    owner node['jenkins']['master']['user']
    group node['jenkins']['master']['group']
    mode '440'
  end
end

package 'bind'

secrets = credential_secrets
jenkins_cred = secrets['jenkins']['bumpzone']

bumpzone_xml = ::File.join(Chef::Config[:file_cache_path], 'bumpzone', 'config.xml')
checkzone_xml = ::File.join(Chef::Config[:file_cache_path], 'checkzone', 'config.xml')
update_zonefiles_xml = ::File.join(Chef::Config[:file_cache_path], 'update-zonefiles', 'config.xml')

[bumpzone_xml, checkzone_xml, update_zonefiles_xml].each do |d|
  directory ::File.dirname(d) do
    recursive true
  end
end

template bumpzone_xml do
  source 'bumpzone.config.xml.erb'
  mode '440'
  variables(
    github_url: bumpzone['github_url'],
    trigger_token: jenkins_cred['trigger_token']
  )
end

template checkzone_xml do
  source 'checkzone.config.xml.erb'
  mode '440'
  variables(
    github_url: bumpzone['github_url'],
    trigger_token: jenkins_cred['trigger_token']
  )
end

template update_zonefiles_xml do
  source 'update-zonefiles.config.xml.erb'
  mode '440'
  variables(
    github_url: bumpzone['github_url'],
    dns_master: bumpzone['dns_master']
  )
end

jenkins_job 'bumpzone' do
  config bumpzone_xml
  action :create
end

jenkins_job 'checkzone' do
  config checkzone_xml
  action :create
end

jenkins_job 'update-zonefiles' do
  config update_zonefiles_xml
  action :create
end
