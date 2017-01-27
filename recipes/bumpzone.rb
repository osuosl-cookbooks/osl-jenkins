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

cookbook_file ::File.join(bumpzone['bin_path'], 'bumpzone.rb') do
  source 'bin/bumpzone.rb'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode 0550
end

cookbook_file ::File.join(bumpzone['lib_path'], 'bumpzone.rb') do
  source 'lib/bumpzone.rb'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode 0440
end

{
  'git' => '2.5.2',
  'github' => '1.19.1',
  'build-token-root' => '1.4',
  'parameterized-trigger' => '2.30',
  'text-finder' => '1.10'
}.each do |p, v|
  jenkins_plugin p do
    version v
    notifies :restart, 'service[jenkins]'
  end
end
