name             'osl-jenkins'
maintainer       'Oregon State University'
maintainer_email 'systems@osuosl.org'
license          'Apache 2.0'
description      'Installs/Configures osl-jenkins'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.8.5'
issues_url       'https://github.com/osuosl-cookbooks/osl-jenkins/issues'
source_url       'https://github.com/osuosl-cookbooks/osl-jenkins'

depends          'base'
depends          'build-essential'
depends          'git'
depends          'java'
depends          'jenkins', '~> 5.0.1'
depends          'osl-haproxy'
depends          'ssh-keys'
depends          'certificate'
depends          'poise-python'
depends          'git'
depends          'sudo'
depends          'sbp_packer', '= 1.4.7'

supports         'centos', '~> 6.0'
supports         'centos', '~> 7.0'
