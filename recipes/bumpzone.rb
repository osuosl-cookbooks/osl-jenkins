#
# Cookbook:: osl-jenkins
# Recipe:: bumpzone
#
# Copyright:: 2017, Oregon State University
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
include_recipe 'osl-jenkins::master'

bumpzone = node['osl-jenkins']['bumpzone']

# Install necessary gems
%w(git octokit).each do |g|
  chef_gem g do # ~FC009
    compile_time true
  end
end

[
  bumpzone['bin_path'],
  bumpzone['lib_path']
].each do |d|
  directory d do
    recursive true
  end
end

%w(bumpzone.rb checkzone.rb).each do |f|
  cookbook_file ::File.join(bumpzone['bin_path'], f) do
    source "bin/#{f}"
    owner node['jenkins']['master']['user']
    group node['jenkins']['master']['group']
    mode 0550
  end

  cookbook_file ::File.join(bumpzone['lib_path'], f) do
    source "lib/#{f}"
    owner node['jenkins']['master']['user']
    group node['jenkins']['master']['group']
    mode 0440
  end
end

{
  'mailer' => '1.20',
  'token-macro' => '2.1',
  'git' => '3.2.0',
  'github' => '1.26.2',
  'matrix-project' => '1.7.1',
  'build-token-root' => '1.4',
  'parameterized-trigger' => '2.33',
  'text-finder' => '1.10',
  'script-security' => '1.27'
}.each do |p, v|
  jenkins_plugin p do
    version v
    notifies :execute, 'jenkins_command[safe-restart]'
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
  mode 0440
  variables(
    github_url: bumpzone['github_url'],
    trigger_token: jenkins_cred['trigger_token']
  )
end

template checkzone_xml do
  source 'checkzone.config.xml.erb'
  mode 0440
  variables(
    github_url: bumpzone['github_url'],
    trigger_token: jenkins_cred['trigger_token']
  )
end

template update_zonefiles_xml do
  source 'update-zonefiles.config.xml.erb'
  mode 0440
  variables(
    github_url: bumpzone['github_url'],
    dns_master: bumpzone['dns_master']
  )
end

jenkins_job 'bumpzone' do
  config bumpzone_xml
  action [:create, :enable]
end

jenkins_job 'checkzone' do
  config checkzone_xml
  action [:create, :enable]
end

jenkins_job 'update-zonefiles' do
  config update_zonefiles_xml
  action [:create, :enable]
end
