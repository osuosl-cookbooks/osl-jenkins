osl-jenkins CHANGELOG
=====================

This file is used to list changes made in each version of the
osl-jenkins cookbook.

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
