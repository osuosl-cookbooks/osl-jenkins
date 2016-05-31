#
# Cookbook Name:: osl-jenkins
# Recipe:: osl_cookbook_uploader
#
# Copyright (C) 2016 Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# This recipe simply sets attributes specific to OSL infrastucture and then
# runs the cookbook_uploader recipe.

node.set['osl-jenkins']['cookbook_uploader']['org'] = 'osuosl-cookbooks'
node.set['osl-jenkins']['cookbook_uploader']['chef_repo'] = 'osuosl/chef-repo'
node.set['osl-jenkins']['cookbook_uploader']['authorized_users'] = []
node.set['osl-jenkins']['cookbook_uploader']['authorized_orgs'] = []
node.set['osl-jenkins']['cookbook_uploader']['authorized_teams'] = \
  ['osuosl-cookbooks/staff']
node.set['osl-jenkins']['cookbook_uploader']['default_environments'] = \
  %w(production dev workstation openstack_production openstack_staging phpbb)

node.set['osl-jenkins']['cookbook_uploader']['override_repos'] = \
  %w(lanparty osl-jenkins)

include_recipe 'osl-jenkins::cookbook_uploader'
