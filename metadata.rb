name             'osl-jenkins'
maintainer       'Oregon State University'
maintainer_email 'systems@osuosl.org'
license          'Apache 2.0'
description      'Installs/Configures osl-jenkins'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.9.9'
issues_url       'https://github.com/osuosl-cookbooks/osl-jenkins/issues'
source_url       'https://github.com/osuosl-cookbooks/osl-jenkins'

depends          'base', '>= 2.6.0'
depends          'build-essential'
depends          'git'
depends          'java'
depends          'jenkins', '~> 5.0.1'
depends          'osl-haproxy'
depends          'osl-docker'
depends          'ssh-keys'
depends          'certificate'
depends          'poise-python'
depends          'git'
depends          'runit', '< 4.0.0'
depends          'sudo'
depends          'yum-plugin-versionlock'
depends          'yum-qemu-ev'
supports         'centos', '~> 6.0'
supports         'centos', '~> 7.0'
