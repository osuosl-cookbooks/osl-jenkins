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
