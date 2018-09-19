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

# install dependencies for gem dependencies at compile time so that chef_gem can use them
node.override['build-essential']['compile_time'] = true
include_recipe 'build-essential::default'

# setup qemu so that we can build images!
include_recipe 'yum-qemu-ev::default'
include_recipe 'base::kvm'

# setup chefdk so that we have berks
include_recipe 'base::chefdk'

# setup packer so that we can build images
include_recipe 'base::packer'

# Setup openstack client so we can uplod images
include_recipe 'base::openstackclient'

# Create directory for builds and other artifacts
directory '/home/alfred/workspace' do
  owner 'alfred'
  group 'alfred'
end

# git aliases & other config to make things easier
cookbook_file '/home/alfred/.gitconfig' do
  source 'gitconfig'
  owner 'alfred'
  group 'alfred'
end

# put the key associated with the openstack_taster's users on various clusters
# so that it can access the instances once created
node.override['osl-jenkins']['secrets_databag'] = 'osl_jenkins'
node.override['osl-jenkins']['secrets_item'] = 'jenkins1'
github_credentials = credential_secrets['git']['packer_pipeline']

# ~/.git-credentials for use by various shell scripts
template '/home/alfred/.git-credentials' do
  owner 'alfred'
  group 'alfred'
  source 'git_credentials.erb'
  mode 0600
  variables(
    username: github_credentials['user'],
    password: github_credentials['token']
  )
end

# put the key associated with the openstack_taster's users on various clusters
# so that it can access the instances once created
node.override['osl-jenkins']['secrets_databag'] = 'osl_jenkins'
node.override['osl-jenkins']['secrets_item'] = 'jenkins1'

openstack_access_keys = credential_secrets['jenkins']['packer_pipeline']

# this is the key that's put on the instances created by openstack_taster
# it has been manually put in all OpenStack Taster account on our clusters.
file '/home/alfred/.ssh/packer_alfred_id.pub' do
  content openstack_access_keys['public_key']
  owner 'alfred'
  group 'alfred'
  mode 0600
end

# this is the private key part of the above keypair to actually ssh into
# those instances and run our suites
file '/home/alfred/.ssh/packer_alfred_id' do
  content openstack_access_keys['private_key']
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

# install openstack_taster
chef_gem 'openstack_taster' do
  compile_time true
  options '--no-user-install'
  clear_sources true
  action :upgrade
end
