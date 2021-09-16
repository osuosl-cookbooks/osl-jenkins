osl-jenkins CHANGELOG
=====================

This file is used to list changes made in each version of the
osl-jenkins cookbook.

2.15.2 (2021-09-16)
-------------------
- Fix regex

2.15.1 (2021-09-16)
-------------------
- Add support for 'main' branches instead of 'master'

2.15.0 (2021-09-15)
-------------------
- Update to users ~> 8.0

2.14.0 (2021-09-08)
-------------------
- Initial terminology update

2.13.4 (2021-06-08)
-------------------
- Update to Jenkins 2.289.1

2.13.3 (2021-05-24)
-------------------
- Disable DES-CBC3-SHA cipher (CVE-2016-2183)

2.13.2 (2021-05-17)
-------------------
- Update to Jenkins 2.277.4

2.13.1 (2021-04-14)
-------------------
- Put a ceiling on users cookbook

2.13.0 (2021-04-06)
-------------------
- Update Chef dependency to >= 16

2.12.0 (2021-03-17)
-------------------
- Bump yum-versionlock cookbook version

2.11.3 (2021-01-27)
-------------------
- Update to Jenkins 2.263.3 and all plugins

2.11.2 (2021-01-13)
-------------------
- Temporarily disable installation of the openstack_taster gem

2.11.1 (2020-12-11)
-------------------
- Update openstack environment name

2.11.0 (2020-11-03)
-------------------
- install gems directly

2.10.0 (2020-10-26)
-------------------
- Update java cookbook version lock

2.9.0 (2020-10-23)
------------------
- Chef 16 Fixes

2.8.4 (2020-08-11)
------------------
- Update to centos 8

2.8.3 (2020-08-06)
------------------
- Bump to jenkins 2.235.3

2.8.2 (2020-07-29)
------------------
- Update ruby paths in scripts to Cinc ruby

2.8.1 (2020-07-28)
------------------
- Switch to using cinc-workstation

2.8.0 (2020-07-20)
------------------
- Chef 15 fixes

2.7.2 (2020-04-06)
------------------
- Use https for pelican staging

2.7.1 (2020-03-31)
------------------
- Pin java cookbook to < 8.0

2.7.0 (2020-02-12)
------------------
- Update osl-haproxy version

2.6.4 (2020-01-21)
------------------
- Add plugins to PowerCI and IBMZ

2.6.3 (2020-01-17)
------------------
- Update git plugin to 4.0.0

2.6.2 (2020-01-17)
------------------
- Add aarch64 to packer pipeline

2.6.1 (2020-01-07)
------------------
- Use vhost hostname for jenkins server webhooks

2.6.0 (2019-12-23)
------------------
- Chef 14 post-migration fixes

2.5.4 (2019-12-18)
------------------
- Remove openstack_queens

2.5.3 (2019-12-11)
------------------
- Migrate away from using poise-python

2.5.2 (2019-12-09)
------------------
- Add openstack_rocky environment

2.5.1 (2019-12-06)
------------------
- Use username/password for cli executor instead of ssh key

2.5.0 (2019-12-05)
------------------
- Bump to jenkins-2.190.3 and other various fixes

2.4.1 (2019-12-05)
------------------
- Update matrix-auth and cloudbees-folder for security issues

2.4.0 (2019-12-02)
------------------
- Chef 14

2.3.2 (2019-12-02)
------------------
- Ensure we only install < 2.0 for openstack_taster

2.3.1 (2019-09-19)
------------------
- Remove reliance on chef-sugar since we don't need it here anyway

2.3.0 (2019-07-15)
------------------
- Convert to using users_manage resource

2.2.9 (2019-06-13)
------------------
- Remove openstack_pike environment

2.2.8 (2019-06-11)
------------------
- Add openstack_queens environment to default bump

2.2.7 (2019-05-30)
------------------
- Remove SGE backend to powerci

2.2.6 (2019-05-29)
------------------
- Remove openstack_ocata environment since it's no longer used

2.2.5 (2019-05-17)
------------------
- Docker plugin updates

2.2.4 (2019-05-08)
------------------
- Add credentials access to users on powerci & ibmz-ci

2.2.3 (2019-04-16)
------------------
- Set alfred gid/uid to something static

2.2.2 (2019-04-16)
------------------
- Add docker-custom-build-environment plugin on powerci and ibmz-ci instances

2.2.1 (2019-04-15)
------------------
- Bump to jenkins-2.164.2

2.2.0 (2019-04-15)
------------------
- Refactor plugins attribute to use hash instead of array

2.1.1 (2019-04-12)
------------------
- Add openstack_pike environment to default bump

2.1.0 (2019-04-03)
------------------
- Update to Jenkins 2.164.1 and bump upstream cookbook to latest

2.0.11 (2019-01-24)
-------------------
- Bump to jenkins-2.150.2

2.0.10 (2019-01-15)
-------------------
- Remove gwm and phase_out_nginx environments

2.0.9 (2019-01-10)
------------------
- Add CUDA 10.0 images

2.0.8 (2019-01-02)
------------------
- Rename environment openstack_newton -> openstack_ocata

2.0.7 (2018-11-19)
------------------
- Fix bug when templates use an inline script

2.0.6 (2018-11-15)
------------------
- Add privileged docker labels for powerci/ibmz-ci

2.0.5 (2018-11-02)
------------------
- Remove docker-gpu-cuda91 label

2.0.4 (2018-10-25)
------------------
- Various Updates

2.0.3 (2018-10-17)
------------------
- Update docker images for powerci

2.0.2 (2018-10-16)
------------------
- Add Ubuntu 18.04 on powerci/ibmz-ci

2.0.1 (2018-10-15)
------------------
- Set SSH connection timeout to 600 seconds

2.0.0 (2018-09-19)
------------------
- Chef 13 compatibility

1.10.18 (2018-08-24)
--------------------
- Update to Jenkins 2.121.3

1.10.17 (2018-08-08)
--------------------
- Create new GPU labels for CUDA 9.1 and 9.2

1.10.16 (2018-08-08)
--------------------
- Disable OpenStack cloud in powerci due to potential issues

1.10.15 (2018-07-11)
--------------------
- Fix typo in deploy

1.10.14 (2018-07-11)
--------------------
- Refactor !deploy yet again

1.10.13 (2018-07-10)
--------------------
- Add more enhancements to !deploy functionality

1.10.12 (2018-07-02)
--------------------
- Deal with issue comment payloads properly with packer pipeline

1.10.11 (2018-07-02)
--------------------
- Switch to using docker_gpu queue on SGE for powerci

1.10.10 (2018-06-27)
--------------------
- Always upgrade openstack_taster

1.10.9 (2018-06-13)
-------------------
- Install ansicolor per RT:30017

1.10.8 (2018-05-30)
-------------------
- Update to jenkins-2.107.3

1.10.7 (2018-05-25)
-------------------
- Add build-timeout plugin per RT:30007

1.10.6 (2018-05-14)
-------------------
- Revert "Use SSH instead of HTTPS for pulling github repos"

1.10.5 (2018-05-14)
-------------------
- Use SSH instead of HTTPS for pulling github repos

1.10.4 (2018-05-11)
-------------------
- Add jenkins job for building docs PRs

1.10.3 (2018-04-23)
-------------------
- Add ccache volume to all docker instances for POWER/IBM-Z CI

1.10.2 (2018-04-18)
-------------------
- Update to jenkins-2.107.2

1.10.1 (2018-04-12)
-------------------
- Translate characters on hostnames which contain - to _ for function names

1.10.0 (2018-04-12)
-------------------
- Add IBM-Z recipe and other fixes

1.9.19 (2018-03-22)
-------------------
- Update subversion and git plugins for security patches

1.9.18 (2018-03-14)
-------------------
- Install build-token-root and its dependencies for powerci users

1.9.17 (2018-03-05)
-------------------
- Install SGE jenkins plugin on powerci

1.9.16 (2018-02-24)
-------------------
- Bump to jenkins-2.89.4

1.9.15 (2018-02-19)
-------------------
- Add osuosl/ubuntu-ppc64le-cuda:9.1-cudnn7 image to powerci

1.9.14 (2018-02-13)
-------------------
- Add osuosl/ubuntu-ppc64le-cuda:9.0-cudnn7 image top powerci

1.9.13 (2018-01-29)
-------------------
- Update plugins with security updates / Bump to jenkins-2.89.3

1.9.12 (2017-12-27)
-------------------
- Install openstackclient using base::openstackclient

1.9.11 (2017-12-20)
-------------------
- Disable throttle for packer builds

1.9.10 (2017-12-19)
-------------------
- Bump openstack_taster to 1.0.2

1.9.9 (2017-12-18)
------------------
- Adjust timeouts for packer jobs

1.9.8 (2017-12-18)
------------------
- Install packer using base::packer instead

1.9.7 (2017-12-18)
------------------
- Update to Jenkins-2.89.2 and also update script-security plugin

1.9.6 (2017-11-27)
------------------
- Fix ChefSpec tests

1.9.5 (2017-11-12)
------------------
- Bump github-api to 1.90 to work around issue with their API

1.9.4 (2017-11-10)
------------------
- Add copy-to-slave plugin for powerci use

1.9.3 (2017-10-31)
------------------
- Add CUDA images to POWERCI

1.9.2 (2017-10-19)
------------------
- Update to jenkins-2.73.2

1.9.1 (2017-10-13)
------------------
- Use openstack_newton instead of openstack_mitaka for default chef env…

1.9.0 (2017-10-12)
------------------
- Manually setup docker jenkins with images and host

1.8.19 (2017-10-09)
-------------------
- Remove testing env from default env

1.8.18 (2017-10-05)
-------------------
- Dependent templates are now searched for by using full path.

1.8.17 (2017-10-02)
-------------------
- Remove cass remnants in osl-jenkins

1.8.16 (2017-09-22)
-------------------
- Ratelimit and add a quiet period to packer_pipeline.

1.8.15 (2017-09-08)
-------------------
- Set status on PR for packer-templates repo

1.8.14 (2017-09-08)
-------------------
- Use git credentials in packer_pipeline

1.8.13 (2017-08-31)
-------------------
- Setup chefdk on packer-pipeline nodes

1.8.12 (2017-08-29)
-------------------
- Use the Jenkinsfile from packer-templates/master branch

1.8.11 (2017-08-28)
-------------------
- openstack client for pipeline nodes

1.8.10 (2017-08-23)
-------------------
- plugin with inbuilt capabilities of readJSON & writeJSON

1.8.9 (2017-08-15)
------------------
- use yum-qemu-ev instead of base for setting qemu-kvm

1.8.8 (2017-08-14)
------------------
- Update to Jenkins 2.60.2

1.8.7 (2017-08-14)
------------------
- Update various plugins which have security updates

1.8.6 (2017-08-11)
------------------
- Fix for #94

1.8.5 (2017-08-10)
------------------
- install openstack_taster as a chef_gem explicitly

1.8.4 (2017-08-07)
------------------
- add packer_pipeline job

1.8.3 (2017-08-07)
------------------
- the real true packer pipeline job

1.8.2 (2017-08-03)
------------------
- setup keys to use with openstack taster

1.8.1 (2017-07-30)
------------------
- Add deploy.sh for bento pipeline

1.8.0 (2017-07-30)
------------------
- ruby things to handle the needs of bento pipeline

1.7.0 (2017-07-29)
------------------
- Setting up nodes for packer pipeline

1.6.2 (2017-07-25)
------------------
- trivial change to re-open PR

1.6.1 (2017-06-30)
------------------
- remove docs builder until fixed

1.6.0 (2017-06-30)
------------------
- Add recipe for power-ci

1.5.3 (2017-06-29)
------------------
- add missing 'htdocs'

1.5.2 (2017-06-28)
------------------
- Add gwm environment to default cookbook bumps

1.5.1 (2017-06-28)
------------------
- Kennric/GitHub org fixes

1.5.0 (2017-06-28)
------------------
- Remove osl_cookbook_uploader / Add missing recipes to jenkins1

1.4.0 (2017-06-28)
------------------
- Kennric/pr build jobs

1.3.1 (2017-06-14)
------------------
- Bump to jenkins-2.46.3

1.3.0 (2017-06-13)
------------------
- Install plugins all from one recipe

1.2.0 (2017-05-25)
------------------
- Kennric/pr comment job

1.1.4 (2017-05-05)
------------------
- Set canRoam to false so assigned node works properly

1.1.3 (2017-05-02)
------------------
- Updating to 2.46.2

1.1.2 (2017-04-27)
------------------
- Assign master node for bumpzone/checkzone jobs

1.1.1 (2017-04-20)
------------------
- Enable Octokit API caching

1.1.0 (2017-04-20)
------------------
- Jenkins scripts and logic for automatically updating/checking the zonefiles

1.0.3 (2017-04-13)
------------------
- Update list of default environments the bump ~ command uses

1.0.2 (2017-04-12)
------------------
- Update ghprb plugin which supports Jenkins 2.0

1.0.1 (2017-04-12)
------------------
- Update pinned versions of various jenkins plugins

1.0.0 (2017-04-12)
------------------
- Upgrade to jenkins-2.46.1

0.12.0 (2017-03-28)
-------------------
- Kennric/pr comment script

0.11.0 (2017-03-17)
-------------------
- Add ssh private key credential support

0.10.0 (2017-02-28)
-------------------
- Bind Serial Updater

0.9.3 (2017-02-17)
------------------
- Update README

0.9.2 (2017-02-17)
------------------
- Move jenkins_private_key to master recipe so it can be used elsewhere

0.9.1 (2017-02-17)
------------------
- Switch to using Jenkins API token instead of password

0.9.0 (2017-02-17)
------------------
- Move .git-credentials and jenkins credential management into master recipe

0.8.0 (2017-02-10)
------------------
- Create recipe for jenkins1.o.o that replicates roles

0.7.28 (2017-01-11)
-------------------
- Remove this version dep as it's causing issues in other places

0.7.27 (2017-01-11)
-------------------
- Use base::chefdk recipe for installing chefdk

0.7.26 (2016-08-19)
-------------------
- Use knife cookbook upload instead of berkshelf

0.7.25 (2016-08-03)
-------------------
- Set chefdk version on jenkins to 0.14.25

0.7.24 (2016-07-19)
-------------------
- Remove extra gem install of octokit

0.7.23 (2016-07-19)
-------------------
- Lock version per plugin

0.7.22 (2016-06-19)
-------------------
- Manually set jenkins java path to stop restarts during chef runs

0.7.21 (2016-06-16)
-------------------
- Revert "Revert "Make sure to update master branch before creating bra…

0.7.20 (2016-06-16)
-------------------
- Remove dev environment from default envs

0.7.19 (2016-06-16)
-------------------
- Revert "Make sure to update master branch before creating branches"

0.7.18 (2016-06-15)
-------------------
- Use correct data bag key

0.7.17 (2016-06-15)
-------------------
- Enable all repos for github

0.7.16 (2016-06-15)
-------------------
- Remove envvars

0.7.15 (2016-06-15)
-------------------
- Fix berkshelf

0.7.14 (2016-06-15)
-------------------
- Make sure to update master branch before creating branches

0.7.13 (2016-06-15)
-------------------
- Use berks update instead of install

0.7.12 (2016-06-15)
-------------------
- Update depends

0.7.10 (2016-06-15)
-------------------
- Set roam to false for jobs

0.7.4 (2016-06-15)
------------------
- Use symbol instead of string for jenkins user and pass key

0.7.3 (2016-06-15)
------------------
- Minor fixes for production jenkins instance

0.5.0
-----
- Adds the chef\_ci\_cookbook\_template recipe for installing `chefdk`.
- Dependency on the `chef-dk` cookbook added.

0.4.0
-----
- Adds the haproxy recipe for setting haproxy attributes.

0.3.0
-----
- Adds the master recipe for setting the package version
  and listening for requests on localhost.

0.2.0
-----
- Adds chef\_backup recipe for installing the ``knife-backup`` plugin
  and managing the ``/var/chef-backup-for-rdiff`` directory.
- CentOS image updated to 6.6 in test-kitchen cloud config.
- Initial Rubocop config added.

0.1.0
-----
- Initial release of osl-jenkins
