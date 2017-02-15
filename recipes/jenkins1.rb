#
# Cookbook:: osl-jenkins
# Recipe:: jenkins1
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
node.default['osl-jenkins']['cookbook_uploader'].tap do |conf|
  conf['authorized_teams'] = %w(osuosl-cookbooks/staff)
  conf['chef_repo'] = 'osuosl/chef-repo'
  conf['default_environments'] = %w(
    production
    workstation
    openstack_production
    openstack_staging
    phpbb
  )
  conf['org'] = 'osuosl-cookbooks'
end
node.default['osl-jenkins']['secrets_item'] = 'jenkins1'

include_recipe 'osl-jenkins::master'
include_recipe 'osl-jenkins::chef_ci_cookbook_template'
include_recipe 'osl-jenkins::osl_cookbook_uploader'

python_runtime '2'

# depends for sphinx compilation
package 'graphviz'
