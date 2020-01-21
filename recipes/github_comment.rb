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
node.default['osl-jenkins']['gems'] += %w(git octokit faraday-http-cache)
include_recipe 'osl-jenkins::master'

bin_path = node['osl-jenkins']['bin_path']
lib_path = node['osl-jenkins']['lib_path']

cookbook_file ::File.join(bin_path, 'github_comment.rb') do
  source 'bin/github_comment.rb'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode 0550
end

cookbook_file ::File.join(lib_path, 'github_comment.rb') do
  source 'lib/github_comment.rb'
  owner node['jenkins']['master']['user']
  group node['jenkins']['master']['group']
  mode 0440
end

github_comment_xml = ::File.join(Chef::Config[:file_cache_path], 'github_comment', 'config.xml')

directory ::File.dirname(github_comment_xml) do
  recursive true
end

template github_comment_xml do
  source 'github_comment.config.xml.erb'
  mode 0440
end

jenkins_job 'github_comment' do
  config github_comment_xml
  action :create
end
