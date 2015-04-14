#
# Cookbook Name:: osl-jenkins
# Recipe:: default
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

begin
  jenkins = ::Chef::EncryptedDataBagItem.load('ssh-keys', 'osl-jenkins')
rescue
  raise 'Error loading data bag item: osl-jenkins. Data bag or data bag item' \
        ' does not exist.'
end

jenkins_user 'jenkins' do
  public_keys [jenkins['id_rsa.pub']]
end

node.run_state['jenkins_private_key'] = jenkins['id_rsa']
