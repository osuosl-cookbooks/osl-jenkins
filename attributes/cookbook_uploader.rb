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
