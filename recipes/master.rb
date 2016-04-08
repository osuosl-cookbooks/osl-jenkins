#
# Cookbook Name:: osl-jenkins
# Recipe:: master
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

# Don't automatically update jenkins
node.override['yum-cron']['yum_parameter'] = '-x jenkins'

node.default['jenkins']['master']['version'] = '1.654-1.1'
node.default['jenkins']['master']['listen_address'] = '127.0.0.1'

# depends for sphinx compilation
package 'graphviz'

node.default['java']['jdk_version'] = '8'

node.default['certificate'] = [{
  'wildcard' => {
    'cert_file' => 'wildcard.pem',
    'key_file' => 'wildcard.key',
    'chain_file' => 'wildcard-bundle.crt',
    'combined_file' => true
  }
}]

include_recipe 'java'
include_recipe 'jenkins::master'
include_recipe 'certificate::manage_by_attributes'
include_recipe 'osl-jenkins::haproxy'
include_recipe 'osl-haproxy::default'

# CentOS 6 packages Git 1.7.1, but we need at least Git 1.7.9 for the
# .git-credentials file to work (needed for the cookbook_uploader recipe), and
# the Jenkins git plugin recommends 1.8.x. So we use 1.8.5.5, the latest 1.8.x.
node.set['git']['version'] = '1.8.5.5'
node.set['git']['checksum'] = '106b480e2b3ae8b02e5b6b099d7a4049f2b1128659ac81f317267d2ed134679f'
include_recipe 'git::source'

include_recipe 'osl-jenkins::chef_ci_cookbook_template'

python_runtime '2'
