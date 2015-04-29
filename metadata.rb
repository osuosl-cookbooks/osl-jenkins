name             'osl-jenkins'
maintainer       'Oregon State University'
maintainer_email 'systems@osuosl.org'
license          'Apache 2.0'
description      'Installs/Configures osl-jenkins'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.3.0'

depends          'jenkins'
depends          'osl-haproxy'
depends          'chef-dk'
