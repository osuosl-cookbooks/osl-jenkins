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
include_recipe 'osl-jenkins::github_comment'

site_pr_builder = node['osl-jenkins']['site_pr_builder']

site_pr_builder['sites_to_build'].each do |site, org|
  job_name = "#{site}_pr_builder"
  repo = "#{org}/#{site}"
  github_url = "https://github.com/#{repo}"
  rsync_target = "/var/www/staging.osuosl.org/htdocs/#{site}-$ghprbPullId"
  site_url = "https://#{site}-$ghprbPullId.staging.osuosl.org"

  site_pr_builder_xml = ::File.join(Chef::Config[:file_cache_path], job_name, 'config.xml')

  directory ::File.dirname(site_pr_builder_xml) do
    recursive true
  end

  template site_pr_builder_xml do
    source 'site_pr_builder_config.xml.erb'
    mode 0440
    variables(
      name: site,
      repo: repo,
      github_url: github_url,
      site_url: site_url,
      rsync_target: rsync_target
    )
  end

  jenkins_job job_name do
    config site_pr_builder_xml
    action :create
  end
end
