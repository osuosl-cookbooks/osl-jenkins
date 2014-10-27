#
# Cookbook Name:: osl-jenkins
# Recipe:: default
#
# Copyright 2014, Oregon State University
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

# Manage a proxy between localhost:8080 and the outside world

apache_app node['osl-apache']['hostname'] do
    include_config true
    include_name "jenkins_proxy"
    include_dir "osl-jenkins"
    cookbook_include "osl-jenkins"
    ssl_enable true
    cert_file "/etc/pki/tls/certs/test-jenkins.example.org.pem"
    cert_key "/etc/pki/tls/private/test-jenkins.example.org.key"
    directive_http [ "Redirect Permanent / https://#{node['osl-apache']['hostname']}/" ]
    directive_https [
        "ProxyPreserveHost on",
        "ProxyPass / http://localhost:8080/",
        "ProxyPassReverse / http://localhost:8080/",
        "ProxyPassReverse / https://#{node['osl-apache']['hostname']}/"
    ]
    site_enable true
end
