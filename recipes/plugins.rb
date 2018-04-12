#
# Cookbook Name:: osl-jenkins
# Recipe:: plugins
#
# Copyright 2015, Oregon State University
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

# Install plugins that need to be loaded later for Chef to function and require a Jenkins restart immediately
node['osl-jenkins']['restart_plugins'].each do |plugins_version|
  p, v = plugins_version.split(':')
  jenkins_plugin p do
    version v
    install_deps false
    notifies :execute, 'jenkins_command[safe-restart]', :immediately
  end
end

reload_file = ::File.join(Chef::Config[:file_cache_path], 'reload-jenkins')

file reload_file do
  action :nothing
end

# Install plugins that can allow for Jenkins restarts later
node['osl-jenkins']['plugins'].each do |plugins_version|
  p, v = plugins_version.split(':')
  jenkins_plugin p do
    version v
    install_deps false
    notifies :execute, 'jenkins_command[safe-restart]'
    notifies :touch, "file[#{reload_file}]", :immediately
  end
end

log 'Safe Restart Jenkins' do
  message 'Safe Restart Jenkins'
  only_if { ::File.exist?(reload_file) }
  notifies :execute, 'jenkins_command[safe-restart]', :immediately
end

file reload_file do
  action :delete
end
