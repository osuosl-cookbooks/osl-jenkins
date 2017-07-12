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


#Setup the user and add keys for ssh-ing
include_recipe 'osl-jenkins::default'

#Create directory for builds and other artifacts
directory '/home/alfred/workspace'

#put the credentials for accessing openstack in alfred's home dir from the
#encrypted databag
secrets = credential_secrets
arch = node['hostnamectl']['architecture']

file '/home/alfred/openstack_credentials'
  content secrets[arch]
  mode 0600
}

#install openstack_taster
