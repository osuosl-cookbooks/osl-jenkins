#
# Cookbook Name:: osl-jenkins
# Recipe:: chef_ci_cookbook_template
#
# Copyright 2015 Oregon State University
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

chef_gem 'foodcritic' do
  action :install
  version '4.0.0'
end

chef_gem 'rubocop' do
  action :install
  version '0.27.1'
end
