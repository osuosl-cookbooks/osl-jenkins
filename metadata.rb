name             'osl-jenkins'
maintainer       'Oregon State University'
maintainer_email 'systems@osuosl.org'
license          'Apache-2.0'
chef_version     '>= 14.0'
description      'Installs/Configures osl-jenkins'
version          '2.8.3'
issues_url       'https://github.com/osuosl-cookbooks/osl-jenkins/issues'
source_url       'https://github.com/osuosl-cookbooks/osl-jenkins'

depends          'base', '>= 2.6.0'
depends          'osl-git'
depends          'java', '< 8.0'
depends          'jenkins', '~> 7.1.0'
depends          'osl-haproxy'
depends          'osl-docker'
depends          'certificate'
depends          'users'
depends          'yum-plugin-versionlock'
depends          'yum-qemu-ev'

supports         'centos', '~> 7.0'
supports         'centos', '~> 8.0'
