name             'osl-jenkins'
maintainer       'Oregon State University'
maintainer_email 'systems@osuosl.org'
license          'Apache 2.0'
description      'Installs/Configures osl-jenkins'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.5.6'

depends          'chef-dk'
depends          'java'
depends          'jenkins'
depends          'osl-haproxy'
depends          'ssh-keys'
depends          'sudo'

supports         'centos', '~> 6.0'
supports         'centos', '~> 7.0'
