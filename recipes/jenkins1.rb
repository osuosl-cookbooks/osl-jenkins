#
# Cookbook:: osl-jenkins
# Recipe:: jenkins1
#
# Copyright:: 2017-2024, Oregon State University
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
%w(git faraday-http-cache).each do |p|
  chef_gem p do
    compile_time true
  end
end
node.default['osl-jenkins']['cookbook_uploader'].tap do |conf|
  conf['authorized_teams'] = %w(osuosl-cookbooks/staff)
  conf['chef_repo'] = 'osuosl/chef-repo'
  conf['default_environments'] = %w(
    phpbb
    production
    workstation
  )
  conf['org'] = 'osuosl-cookbooks'
end
node.default['osl-jenkins']['secrets_item'] = 'jenkins1'

include_recipe 'osl-jenkins::controller'
# include_recipe 'osl-jenkins::chef_ci_cookbook_template'
# include_recipe 'osl-jenkins::cookbook_uploader'
# include_recipe 'osl-jenkins::github_comment'
# include_recipe 'osl-jenkins::bumpzone'
# include_recipe 'osl-jenkins::site_pr_builder'
# include_recipe 'osl-jenkins::packer_pipeline_controller'
include_recipe 'base::python'

# depends for sphinx compilation
package 'graphviz'
