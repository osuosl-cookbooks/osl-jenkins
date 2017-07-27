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

# put the credentials for accessing openstack in alfred's home dir from the
# encrypted databag
node.override['osl-jenkins']['secrets_databag'] = 'osl_jenkins'
node.override['osl-jenkins']['secrets_item'] = 'packer_pipeline_creds'

include_recipe 'sbp_packer::default'
node.override['packer']['version'] = '1.0.2'

arch = node['kernel']['machine']
if arch == 'ppc64le'
  node.override['packer']['url_base'] = node['osl-jenkins']['packer_pipeline']['packer_ppc64le']['url_base']
  node.override['packer']['checksum'] = node['osl-jenkins']['packer_pipeline']['packer_ppc64le']['sha256sum']
end

openstack_credentials = credential_secrets[arch]

file '/home/alfred/openstack_credentials.json' do
  content openstack_credentials.to_json
  mode 0600
  owner 'alfred'
  group 'alfred'
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
if arch == 'x86_64'
  include_recipe 'base::kvm'
elsif arch == 'ppc64le'
  log 'qemu on ppc64le' do
    message 'Assuming this ppc64le node has been already setup as a OpenStack compute node \
    and skipping qemu installation'
    level :info
  end
end
