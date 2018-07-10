#
# Cookbook Name:: osl-jenkins
# Recipe:: default
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
#

# jenkins 1.612 and above requires java 7
node.default['java']['jdk_version'] = '8'

include_recipe 'java'

group 'alfred' do
  action :create
end

user 'alfred' do
  manage_home true
  gid 'alfred'
  system true
  shell '/bin/bash'
  home '/home/alfred'
  action :create
end

# This is necessary due to a bug in the upstream "ssh_keys" cookbook
ohai 'reload_passwd' do
  action :nothing
  plugin 'etc'
end.run_action(:reload)

node.default['ssh_keys']['alfred'] = 'alfred'
include_recipe 'ssh-keys'
