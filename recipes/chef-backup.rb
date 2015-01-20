#
# Cookbook Name:: osl-jenkins
# Recipe:: chef-backup
#
# Copyright 2014, Oregon State University
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

chef_gem 'knife-backup' do
    action :install
end

directory '/var/chef-backup-for-rdiff' do
    owner node['jenkins']['master']['user']
    group node['jenkins']['master']['group']
end
