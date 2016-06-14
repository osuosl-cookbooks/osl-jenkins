###
### Attributes that you probably want to override:
###

# String; name of GitHub organization that contains your cookbooks.
default['osl-jenkins']['cookbook_uploader']['org'] = ''

# String; full name of GitHub repo that acts as the chef-repo, prefixed with
# the organization name and a slash, e.g. 'myorg/chef-repo'.
default['osl-jenkins']['cookbook_uploader']['chef_repo'] = ''

# Array<String>; List of GitHub users that are allowed to use the !bump
# command. If a user is in this list, they have permission regardless of the
# org or team lists.
default['osl-jenkins']['cookbook_uploader']['authorized_users'] = []

# Array<String>; List of GitHub organizations that are allowed to use the !bump
# command. If a user is a member of any org in this list, they have permission
# regardless of the user or team lists.
default['osl-jenkins']['cookbook_uploader']['authorized_orgs'] = []

# Array<String>; List of GitHub teams that are allowed to use the !bump
# command, prefixed with the organization name and a slash, e.g.
# 'myorg/myteam'. Case-sensitive. If a user is a member of any team in this
# list, they have permission regardless of the user or org lists.
default['osl-jenkins']['cookbook_uploader']['authorized_teams'] = []

# WARNING: If no authorized users, orgs, or teams are set, then permissions are
# disabled and *anyone* can trigger bumps.

# Array<String>; A set of Chef environments that usually need to be bumped when
# using the !bump command. This set can be called rather than listing
# environments individually by using the below `default_environments_word`,
# which is '~' by default, e.g. '!bump patch ~'.
default['osl-jenkins']['cookbook_uploader']['default_environments'] = []

###
### Attributes that you really should put in a databag instead:
###

# It's not secure to store the following as attributes; these are only here for
# documentation and are usually set by test kitchen from environment variables
# for testing. In production, store credentials in the secrets databag
# specified below.

# String; A GitHub API token that has read and write permissions to the
# cookbook org, all repos within the org, and the chef-repo. Webhook creation
# permissions are also required for all repos within the cookbook org.
default['osl-jenkins']['cookbook_uploader']['credentials']['github_token'] = ''

# String; The GitHub username of the user associated with the above API token.
# This is necessary because regular git pull/push operations (as opposed to API
# operations, which just require the token) require a username/password or SSH
# key. You can, however, use an API token in place of a password, and since we
# already have an API token, we just need to username to go with it.
default['osl-jenkins']['cookbook_uploader']['credentials']['github_user'] = ''

# String; A random string that is used to allow GitHub to send pushes to
# Jenkins. Jenkins' job trigger URLs are publicly accessible, so Jenkins will
# ignore POSTs to them unless the correct trigger_token is specified. You can
# generate a random string easily with a command such as `pwgen -s 20 1`.
default['osl-jenkins']['cookbook_uploader']['credentials']['trigger_token'] = ''

# String; If Jenkins has username/password security enabled (as opposed to
# being public and not requiring a login), you must specify a Jenkins user that
# has permission to create jobs since the Jenkins cookbook uses the Jenkins API
# locally to configure new jobs, and so needs credentials.
default['osl-jenkins']['cookbook_uploader']['credentials']['jenkins_user'] = ''

# String; The password associated with the above Jenkins user.
default['osl-jenkins']['cookbook_uploader']['credentials']['jenkins_pass'] = ''

###
### Attributes that you probably don't need to change:
###

# String; The name of the databag to use.
default['osl-jenkins']['cookbook_uploader']['secrets_databag'] = 'osl_jenkins'

# String; The name of the databag item to use.
default['osl-jenkins']['cookbook_uploader']['secrets_item'] = \
  'cookbook_uploader_secrets'

# String; The path in which to store scripts used by the Jenkins jobs.
default['osl-jenkins']['cookbook_uploader']['scripts_path'] = \
  ::File.join(node['jenkins']['master']['home'], 'bin')

# String; The keyword that indicates that the default set of environments
# specified above should be bumped when used in the !bump command.
default['osl-jenkins']['cookbook_uploader']['default_environments_word'] = '~'

# String; The keyword that indicates that all environments should be bumped
# when used in the !bump command.
default['osl-jenkins']['cookbook_uploader']['all_environments_word'] = '*'

###
### Attributes that are mainly for testing:
###

# Array<String>; If "nil", Jenkins automation will be set up for all repos in
# the above cookbook organization. If an array of repo names (not prefixed) is
# given, only they will have the automation set up. This is useful if you wish
# to test automation only on one or two repos before deploying to the entire
# GitHub organization.
default['osl-jenkins']['cookbook_uploader']['override_repos'] = nil

# Boolean; Whether to allow GitHub pushes to insecure URLs; useful for testing
# on a local Jenkins instance that doesn't have a valid SSL cert.
default['osl-jenkins']['cookbook_uploader']['github_insecure_hook'] = false

# Boolean; Whether to actually upload cookbooks to the Chef server; useful for
# testing if you don't actually have access to the Chef server. All other
# actions (e.g. merging and creating PRs) will still be performed.
default['osl-jenkins']['cookbook_uploader']['do_not_upload_cookbooks'] = false
