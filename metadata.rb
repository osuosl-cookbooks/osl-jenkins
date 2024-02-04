name             'osl-jenkins'
maintainer       'Oregon State University'
maintainer_email 'systems@osuosl.org'
license          'Apache-2.0'
chef_version     '>= 16.0'
description      'Installs/Configures osl-jenkins'
version          '2.17.1'
issues_url       'https://github.com/osuosl-cookbooks/osl-jenkins/issues'
source_url       'https://github.com/osuosl-cookbooks/osl-jenkins'

depends          'base', '>= 2.6.0'
depends          'osl-git'
depends          'java', '~> 11.2.2'
depends          'jenkins', '~> 9.5.19'
depends          'osl-haproxy'
depends          'osl-docker'
depends          'certificate'
depends          'users', '~> 8.0'
depends          'yum-plugin-versionlock', '>= 0.4.0'
depends          'yum-qemu-ev'

supports         'centos', '~> 7.0'
supports         'almalinux', '~> 8.0'
