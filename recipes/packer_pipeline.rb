#
# Cookbook Name:: osl-jenkins
# Recipe:: packer_pipeline
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

# Sets up the slaves for packer_pipeline

# Setup the user and add keys for ssh-ing
include_recipe 'osl-jenkins::default'

# Create directory for builds and other artifacts
directory '/home/alfred/workspace'

# put the credentials for accessing openstack in alfred's home dir from the
# encrypted databag
node.override['osl-jenkins']['secrets_databag'] = 'osl_jenkins'
node.override['osl-jenkins']['secrets_item'] = 'packer_pipeline_creds'

arch = node['hostnamectl']['architecture'].sub!('-', '_')
openstack_credentials = credential_secrets[arch]

file '/home/alfred/openstack_credentials.json' do
  content openstack_credentials.to_json
  mode 0600
end

# install openstack_taster
gem 'openstack_taster' do
  source 'https://github.com/osuosl/openstack_taster/releases/download/v0.0.2/openstack_taster-0.0.2.gem'
  clear_sources true
  action :install
end
