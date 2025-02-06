name             'osl-jenkins'
maintainer       'Oregon State University'
maintainer_email 'systems@osuosl.org'
license          'Apache-2.0'
chef_version     '>= 16.0'
description      'Installs/Configures osl-jenkins'
version          '3.3.3'
issues_url       'https://github.com/osuosl-cookbooks/osl-jenkins/issues'
source_url       'https://github.com/osuosl-cookbooks/osl-jenkins'

depends          'base', '>= 2.6.0'
depends          'certificate'
depends          'osl-docker'
depends          'osl-git'
depends          'osl-haproxy'
depends          'osl-repos'
depends          'users', '~> 8.0'

supports         'almalinux', '~> 8.0'
