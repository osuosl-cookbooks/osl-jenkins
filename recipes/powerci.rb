#
# Cookbook Name:: osl-jenkins
# Recipe:: powerci
#
# Copyright 2015, Oregon State University
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
#

# Don't automatically update jenkins
node.override['yum-cron']['yum_parameter'] = '-x jenkins'

node.default['jenkins']['master']['version'] = '2.46.3-1.1'
node.default['jenkins']['master']['listen_address'] = '127.0.0.1'

node.default['java']['jdk_version'] = '8'

# Manually set the jenkins java attribute to stop jenkins being restarted
# every chef run due to logic in
# https://github.com/chef-cookbooks/jenkins/blob/master/attributes/default.rb#L45-L53
node.set['jenkins']['java'] = 'java'

node.default['certificate'] = [{
  'power-ci' => {
    'cert_file' => 'power-ci.pem',
    'key_file' => 'power-ci.key',
    'chain_file' => 'power-ci-bundle.crt',
    'combined_file' => true
  }
}]

include_recipe 'java'
include_recipe 'jenkins::master'
include_recipe 'certificate::manage_by_attributes'

# haproxy settings
node.default['haproxy']['enable_ssl'] = true

node.default['haproxy']['frontend_max_connections'] = '2000' \
  "\n  redirect scheme https if !{ ssl_fc }"

node.default['haproxy']['ssl_incoming_port'] = \
  '443 ssl crt /etc/pki/tls/power-ci.pem ' \
  'ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:' \
  'ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS no-sslv3'

node.default['haproxy']['members'] = [
  {
    'hostname' => 'power-ci',
    'ipaddress' => '127.0.0.1',
    'port' => '8080'
  }
]
include_recipe 'osl-haproxy::default'

if platform_family?('rhel')
  if node['platform_version'].to_i <= 6
    # CentOS 6 packages Git 1.7.1, but we need at least Git 1.7.9 for the
    # .git-credentials file to work (needed for the cookbook_uploader recipe),
    # and the Jenkins git plugin recommends 1.8.x. So we use 1.8.5.5, the
    # latest 1.8.x.
    node.set['git']['version'] = '1.8.5.5'
    node.set['git']['checksum'] = '106b480e2b3ae8b02e5b6b099d7a4049' \
                                  'f2b1128659ac81f317267d2ed134679f'
    include_recipe 'build-essential'
    include_recipe 'git::source'

    # Also create a symlink for when /usr/local/bin isn't in PATH.
    link '/usr/bin/git' do
      to '/usr/local/bin/git'
    end
  else
    # For CentOS 7 and up, the packaged version is new enough.
    include_recipe 'git::package'
  end
end

jenkins_command 'safe-restart' do
  action :nothing
end

node.default['osl-jenkins']['restart_plugins'] = %w(
  credentials:2.1.13
  ssh-credentials:1.13
)
node.default['osl-jenkins']['plugins'] = %w(
  docker-commons:1.6
  ssh-slaves:1.17
  resource-disposer:0.6
  pipeline-model-extensions:1.1.3
  github:1.27.0
  structs:1.6
  emailext-template:1.0
  git:3.3.0
  pipeline-stage-tags-metadata:1.1.3
  workflow-scm-step:2.4
  github-api:1.85
  workflow-cps-global-lib:2.8
  openstack-cloud:2.22
  cloudbees-folder:6.0.3
  junit:1.20
  bouncycastle-api:2.16.1
  display-url-api:2.0
  matrix-project:1.10
  config-file-provider:2.15.7
  handlebars:1.1.1
  credentials-binding:1.11
  workflow-cps:2.30
  workflow-job:2.10
  email-ext:2.57.2
  pipeline-milestone-step:1.3.1
  icon-shim:2.0.3
  authentication-tokens:1.3
  pipeline-rest-api:2.6
  docker-build-publish:1.3.2
  git-client:2.4.5
  jquery-detached:1.2.1
  pipeline-input-step:2.7
  momentjs:1.1.1
  workflow-support:2.14
  pipeline-build-step:2.5
  yet-another-docker-plugin:0.1.0-rc37
  matrix-auth:1.5
  workflow-multibranch:2.14
  branch-api:2.0.8
  embeddable-build-status:1.9
  token-macro:2.1
  workflow-step-api:2.9
  build-monitor-plugin:1.11+build.201701152243
  pipeline-multibranch-defaults:1.1
  pipeline-model-declarative-agent:1.1.1
  ace-editor:1.1
  docker-workflow:1.10
  workflow-durable-task-step:2.11
  workflow-api:2.13
  github-branch-source:2.0.5
  docker-plugin:0.16.2
  pipeline-model-definition:1.1.3
  workflow-basic-steps:2.4
  mailer:1.20
  pipeline-model-api:1.1.3
  pipeline-stage-step:2.2
  durable-task:1.13
  scm-api:2.1.1
  cloud-stats:0.11
  plain-credentials:1.4
  github-oauth:0.27
  pipeline-graph-analysis:1.3
  script-security:1.27
  workflow-aggregator:2.5
  job-restrictions:0.6
  pipeline-stage-view:2.6
  git-server:1.7
)
include_recipe 'osl-jenkins::plugins'
