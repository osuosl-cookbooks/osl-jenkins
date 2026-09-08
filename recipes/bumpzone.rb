#
# Cookbook:: osl-jenkins
# Recipe:: bumpzone
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
bumpzone = node['osl-jenkins']['bumpzone']
repo_owner, repo_name = bumpzone['repo'].split('/')
jenkins_cred = credential_secrets['jenkins']['bumpzone']

# named-checkzone, run by the zonefiles CI pipeline on the controller.
package 'bind'

osl_jenkins_service 'bumpzone' do
  action :nothing
end

# NOTE: the 'bumpzone' credential these jobs use is created out-of-band (Jenkins
# UI), NEVER via JCasC - one JCasC credential wipes the whole credential store.
osl_jenkins_plugin 'github-branch-source' do
  notifies :restart, 'osl_jenkins_service[bumpzone]', :delayed
end

osl_jenkins_plugin 'generic-webhook-trigger' do
  notifies :restart, 'osl_jenkins_service[bumpzone]', :delayed
end

# Zone syntax CI for every branch and PR, reported as native commit statuses.
# Replaces the freestyle checkzone job, which built an arbitrary branch head.
osl_jenkins_job 'zonefiles' do
  source 'jobs/zonefiles_pipeline.groovy.erb'
  template true
  variables(
    job_name: 'zonefiles',
    repo_name: repo_name,
    repo_owner: repo_owner
  )
  notifies :restart, 'osl_jenkins_service[bumpzone]', :delayed
end

# Serial bump on merge. Replaces the freestyle bumpzone job and its
# authenticationToken build token.
osl_jenkins_job 'zone-bumper' do
  source 'jobs/zone_bumper_pipeline.groovy.erb'
  template true
  variables(
    github_url: bumpzone['github_url'],
    job_name: 'zone-bumper',
    pipelines_branch: bumpzone['pipelines_branch'],
    repo: bumpzone['repo'],
    trigger_token: jenkins_cred['trigger_token']
  )
  sensitive true
  notifies :restart, 'osl_jenkins_service[bumpzone]', :delayed
end

# Deploy to the hidden DNS primary. The job NAME is load bearing: osl-dns rsyncs
# from /home/alfred/jenkins/workspace/update-zonefiles/, this job's workspace.
osl_jenkins_job 'update-zonefiles' do
  source 'jobs/update_zonefiles_pipeline.groovy.erb'
  template true
  variables(
    dns_primary: bumpzone['dns_primary'],
    github_url: bumpzone['github_url'],
    job_name: 'update-zonefiles',
    pipelines_branch: bumpzone['pipelines_branch']
  )
  notifies :restart, 'osl_jenkins_service[bumpzone]', :delayed
end

# Retired by the pipelines. Config cleanup only - the server-side jobs are
# deleted by hand. Drop these resources once they have converged everywhere.
%w(bumpzone checkzone).each do |j|
  osl_jenkins_job j do
    action :delete
    notifies :restart, 'osl_jenkins_service[bumpzone]', :delayed
  end
end

%w(bin/bumpzone.rb bin/checkzone.rb lib/bumpzone.rb lib/checkzone.rb lib/yajl_workaround.rb).each do |s|
  file ::File.join('/var/lib/jenkins', s) do
    action :delete
  end
end
