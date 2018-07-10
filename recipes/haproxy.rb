#
# Cookbook Name:: osl-jenkins
# Recipe:: haproxy
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

node.default['haproxy']['enable_ssl'] = true

node.default['haproxy']['frontend_max_connections'] = '2000' \
  "\n  redirect scheme https if !{ ssl_fc }"

node.default['haproxy']['ssl_incoming_port'] = \
  '443 ssl crt /etc/pki/tls/wildcard.pem ' \
  'ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:' \
  'ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS no-sslv3'

node.default['haproxy']['members'] = [
  {
    'hostname' => 'jenkins',
    'ipaddress' => '127.0.0.1',
    'port' => '8080',
  },
]
