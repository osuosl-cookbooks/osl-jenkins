osl-jenkins Cookbook
====================

Jenkins wrapper cookbook for OSL.

Requirements
------------
TODO: List your cookbook requirements. Be sure to include any requirements this cookbook has on platforms, libraries, other cookbooks, packages, operating systems, etc.

e.g.
#### packages
- `toaster` - osl-jenkins needs toaster to brown your bagel.

Attributes
----------
TODO: List your cookbook attributes here.

e.g.
#### osl-jenkins::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['osl-jenkins']['bacon']</tt></td>
    <td>Boolean</td>
    <td>whether to include bacon</td>
    <td><tt>true</tt></td>
  </tr>
</table>

Usage
-----
#### osl-jenkins::default
TODO: Write usage instructions for each cookbook.

#### osl-jenkins::haproxy

Set default haproxy attributes required for proxying HTTPS
traffic to and from Jenkins.

e.g.
Just include `osl-jenkins` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[osl-jenkins]"
  ]
}
```

#### osl-jenkins::chef_backup
Manages dependencies for the `chef-backup` Jenkins job.

Installs the `knife-backup` gem for use by the chef\_client, and ensures
the `/var/chef-backup-for-rdiff` directory exists and is owned by the
jenkins master user and group.

#### osl-jenkins::chef_ci_cookbook_template
Manages dependencies for the `chef-ci-cookbook-template` Jenkins job.

Uses the `chef-dk::default` recipe to install `chefdk`.

#### osl-jenkins::cookbook_uploader
Automates the merging, version updating, changelog updating, tagging, and
uploading of Chef cookbooks, and optionally also creates GitHub PRs for
updating Chef environments to use the new versions.

To set up:
    - Specify a GitHub organization that contains your cookbooks
      (`node['osl-jenkins']['cookbook_uploader']['org']`, e.g.
      `osuosl-cookbooks`)
    - Specify a GitHub repo that contains your chef-repo
      (`node['osl-jenkins']['cookbook_uploader']['chef_repo']` e.g.
      `osuosl/chef-repo`)
    - Create an encrypted data bag (in `osl_jenkins/secrets` by default) that
      contains a GitHub username and API token.  You also need a random trigger
      token string (that GitHub will use to authenticate itself to Jenkins to
      trigger jobs) and a Jenkins username and password for the cookbook itself
      to access Jenkins through (if the Jenkins instance has security enabled).
      For example:

      ```
      {
        "github_user": "githubuser",
        "github_token": "githubtoken",
        "trigger_token": "triggertoken",
        "jenkins_user": "jenkinsuser",
        "jenkins_pass": "jenkinspass"
      }
      ```
    - Add `osl-jenkins::cookbook_uploader` to the node's `run_list`

#### osl-jenkins::packer_pipeline_master
Sets up a Jenkins master to be able to run the packer pipeline described at
[packer-templates/Jenkinsfile](https://github.com/osuosl/packer-templates/tree/master/Jenkinsfile)

#### osl-jenkins::packer_pipeline_node
Sets up a node which will work on linting, packing, building, deploying for test, running several tests using
[OpenStack_Taster](https://github.com/osuosl/openstack_taster/) and then deploy for production.

Test Kitchen
------------

Several of the suites use GitHub API integration to run and require the addition of some environment variables to fully
test.  In order to properly test GitHub integration, you must export the ``GITHUB_USER`` and ``GITHUB_TOKEN`` env vars
in your shell before you converge this suite. To create a Github token, click on settings under your profile and the
click on *Personal access tokens*. Generate a token (give it a name) and ensure it has permission to pull/push private
repos and create webhooks. You also need to choose a random ``TRIGGER_TOKEN`` string (i.e. ``pwgen -s 30 1`` works).
This is what GitHub will use to trigger Jenkins jobs remotely.

These environment variables are required on the following suites:

- bumpzone
- cookbook-uploader
- github-comment
- jenkins1
- packer-pipeline-master
- packer-pipeline-node
- powerci
- site-pr-builder

For example:

``` console
$ export GITHUB_USER=osuosl-manatee
$ export GITHUB_TOKEN=<long string of numbers and letters>
$ export TRIGGER_TOKEN=<output of pwgen -s 30 1>
$ kitchen converge cookbook-uploader
```
It's worth noting that security (i.e. logging in to Jenkins) is not enabled by default, and so remotely triggered build
configuration will not appear when configuring jobs.  It will, however, still be set.  If you enable user/pass
security, then the Jenkins cookbook will not be able to update jobs, since it then has to log in.  To fix this, you
must create a user account for the cookbook and export the ``JENKINS_USER`` and ``JENKINS_PASS`` env vars in addition
to the others.

## Github OAuth

The ``powerci`` suite also uses Github OAuth tokens which requires the addition of the ``GITHUB_CLIENT_ID`` and
``GITHUB_CLIENT_SECRET`` environment vars. To create the OAuth tokens, click on settings under your profile and then
click on *OAuth Apps*. Create a new application and enter the following data:

- Application name: ``powerci``
- Homepage URL: ``https://<test-kitchen IP address>``
- Authorization callback URL: ``https://<test-kitchen IP address>/securityRealm/finishLogin``

Keep in mind that you'll have to update these two URL's whenever you deploy a new app. It doesn't matter what IP
address you give it initially as long as you update it before trying to log into the Jenkins instance.

Contributing
------------

TODO: (optional) If this is a public cookbook, detail the process for contributing. If this is a private cookbook, remove this section.

e.g.
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Authors: TODO: List authors
