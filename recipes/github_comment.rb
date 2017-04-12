#
# Cookbook:: osl-jenkins
# Recipe:: github_comment
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

github_comment = node['osl-jenkins']['github_comment']

# Install necessary gems
%w(git octokit).each do |g|
  chef_gem g do # ~FC009
    compile_time true
  end
end

[
  github_comment['bin_path'],
  github_comment['lib_path']
].each do |d|
  directory d do
    recursive true
  end
end

cookbook_file ::File.join(github_comment['bin_path'], 'github_comment.rb') do
  source 'bin/github_comment.rb'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode 0550
end

cookbook_file ::File.join(github_comment['lib_path'], 'github_comment.rb') do
  source 'lib/github_comment.rb'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode 0440
end

{
  'git' => '3.2.0',
  'github' => '1.26.2',
  'ghprb' => '1.36.1'
}.each do |p, v|
  jenkins_plugin p do
    version v
    notifies :restart, 'service[jenkins]'
  end
end
