name             'osl-jenkins'
maintainer       'Oregon State University'
maintainer_email 'systems@osuosl.org'
license          'Apache-2.0'
chef_version     '>= 12.18' if respond_to?(:chef_version)
description      'Installs/Configures osl-jenkins'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '2.5.4'
issues_url       'https://github.com/osuosl-cookbooks/osl-jenkins/issues'
source_url       'https://github.com/osuosl-cookbooks/osl-jenkins'

depends          'base', '>= 2.6.0'
depends          'build-essential'
depends          'git'
depends          'java'
depends          'jenkins', '~> 7.1.0'
depends          'osl-haproxy'
depends          'osl-docker'
depends          'certificate'
depends          'git'
depends          'sudo'
depends          'users'
depends          'yum-plugin-versionlock'
depends          'yum-qemu-ev'
supports         'centos', '~> 6.0'
supports         'centos', '~> 7.0'
