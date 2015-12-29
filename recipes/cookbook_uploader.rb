#
# Cookbook Name:: osl-jenkins
# Recipe:: cookbook-uploader
#
# Copyright (C) 2015 Oregon State University
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

org = node['osl-jenkins']['org']
secrets = Chef::EncryptedDataBagItem.load(node['osl-jenkins']['databag'],
                                          'secrets')
repos = collect_github_repositories(secrets, org)
repos.each do |repo|
  xml = ::File.join(Chef::Config[:file_cache_path], org, repo, 'config.xml')
  d = ::File.dirname(xml)
  directory d do
    recursive true
  end
  template xml do
    source 'cookbook-uploader.config.xml.erb'
    variables(
      org: org,
      repo: repo
    )
  end
  jenkins_job repo do
    config xml
    action [:create, :enable]
  end
end
