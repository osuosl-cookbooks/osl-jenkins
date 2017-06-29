osl-jenkins CHANGELOG
=====================

This file is used to list changes made in each version of the
osl-jenkins cookbook.

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
