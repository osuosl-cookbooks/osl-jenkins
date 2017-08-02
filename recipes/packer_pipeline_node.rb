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

# Setup the user and add an authorized key entry for the master
include_recipe 'osl-jenkins::default'

# Create directory for builds and other artifacts
directory '/home/alfred/workspace' do
  owner 'alfred'
  group 'alfred'
end

# git aliases to make things easier
cookbook_file '/home/alfred/.gitconfig' do
  source 'gitconfig'
  owner 'alfred'
  group 'alfred'
end

# put the key associated with the openstack_taster's users on various clusters
# so that it can access the instances once created
node.override['osl-jenkins']['secrets_databag'] = 'osl_jenkins'
node.override['osl-jenkins']['secrets_item'] = 'jenkins1'

openstack_access_keys = credential_secrets['jenkins']['packer_pipeline']

file '/home/alfred/.ssh/bento_alfred_id' do
  content openstack_access_keys['private_key']
  owner 'alfred'
  group 'alfred'
  mode 0600
end

file '/home/alfred/.ssh/bento_alfred_id.pub' do
  content openstack_access_keys['public_key']
  owner 'alfred'
  group 'alfred'
  mode 0600
end

# put the credentials for accessing openstack in alfred's home dir from the
# encrypted databag
node.override['osl-jenkins']['secrets_databag'] = 'osl_jenkins'
node.override['osl-jenkins']['secrets_item'] = 'packer_pipeline_creds'

openstack_credentials = credential_secrets[node['kernel']['machine']]
file '/home/alfred/openstack_credentials.json' do
  content openstack_credentials.to_json
  mode 0600
  owner 'alfred'
  group 'alfred'
end

# setup the right packer
if node['kernel']['machine'] == 'ppc64le'
  node.override['packer']['version'] = node['osl-jenkins']['packer_pipeline']['packer_ppc64le']['version']
  remote_file "/usr/local/bin/packer-v#{node['packer']['version']}" do
    source node['osl-jenkins']['packer_pipeline']['packer_ppc64le']['url_base']
    checksum node['osl-jenkins']['packer_pipeline']['packer_ppc64le']['checksum']
    mode '0755'
    action :create
  end

  link '/usr/local/bin/packer' do
    to "/usr/local/bin/packer-v#{node['packer']['version']}"
  end
else
  include_recipe 'sbp_packer::default'
end

# install dependencies for gem dependencies
include_recipe 'build-essential::default'

# install openstack_taster
gem_package 'openstack_taster' do
  version node['osl-jenkins']['packer_pipeline']['openstack_taster_version']
  options '--no-user-install'
  clear_sources true
  action :install
end

# setup qemu so that we can build images!
include_recipe 'base::kvm' if node['kernel']['machine'] == 'x86_64'

log 'qemu on ppc64le' do
  message 'Assuming this ppc64le node has been already setup as a OpenStack compute node \
  and skipping qemu installation'
  level :info
  only_if { node['kernel']['machine'] == 'ppc64le' }
end
