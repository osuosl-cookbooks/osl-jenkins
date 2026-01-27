#
# Cookbook:: osl-jenkins
# Recipe:: github_comment
#
# Copyright:: 2017-2026, Oregon State University
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
%w(
  faraday-http-cache
  git
  octokit
).each do |p|
  chef_gem p do
    compile_time true
  end
end

cookbook_file ::File.join(osl_jenkins_bin_path, 'github_comment.rb') do
  source 'bin/github_comment.rb'
  owner 'jenkins'
  group 'jenkins'
  mode '550'
end

cookbook_file ::File.join(osl_jenkins_lib_path, 'github_comment.rb') do
  source 'lib/github_comment.rb'
  owner 'jenkins'
  group 'jenkins'
  mode '440'
end

osl_jenkins_service 'github_comment' do
  action :nothing
end

osl_jenkins_plugin 'ghprb' do
  notifies :restart, 'osl_jenkins_service[github_comment]', :delayed
end

osl_jenkins_job 'github_comment' do
  source 'jobs/github_comment.groovy'
  file true
  notifies :restart, 'osl_jenkins_service[github_comment]', :delayed
end
