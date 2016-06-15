name             'osl-jenkins'
maintainer       'Oregon State University'
maintainer_email 'systems@osuosl.org'
license          'Apache 2.0'
description      'Installs/Configures osl-jenkins'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.7.15'

depends          'chef-dk'
depends          'git', '~> 4.3'
depends          'java'
depends          'jenkins', '~> 2.4.0'
depends          'osl-haproxy'
depends          'ssh-keys'
depends          'certificate'
depends          'poise-python'
depends          'git'
depends          'sudo'

supports         'centos', '~> 6.0'
supports         'centos', '~> 7.0'
