###
### Attributes that you probably want to override:
###

# String; jenkins server vhost
default['osl-jenkins']['cookbook_uploader']['jenkins_server'] = 'jenkins.osuosl.org'

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

# String; The keyword that indicates that the default set of environments
# specified above should be bumped when used in the !bump command.
default['osl-jenkins']['cookbook_uploader']['default_environments_word'] = '~'

# String; The keyword that indicates that all environments should be bumped
# when used in the !bump command.
default['osl-jenkins']['cookbook_uploader']['all_environments_word'] = '*'

# String; Git URL of the cookbook-pipelines repo, which holds the shared
# pipeline library (cookbook CI) and the uploader pipeline definitions.
default['osl-jenkins']['cookbook_uploader']['pipelines_repo'] = 'https://github.com/osuosl/cookbook-pipelines.git'

# String; Branch of the cookbook-pipelines repo that Jenkins runs from.
default['osl-jenkins']['cookbook_uploader']['pipelines_branch'] = 'main'

# String; Regex of repo names the CI organization folder will consider. Repos
# not matching are ignored entirely, even if they contain a Jenkinsfile.
# Useful for canarying CI on one or two repos before an org-wide rollout.
default['osl-jenkins']['cookbook_uploader']['ci_repo_filter'] = '.*'

# String; Display name and URL of the GitLab server (gitlab-branch-source),
# used by the data-bags multibranch pipeline. The server name is what job
# definitions reference.
default['osl-jenkins']['cookbook_uploader']['gitlab_server_name'] = 'git.osuosl.org'
default['osl-jenkins']['cookbook_uploader']['gitlab_server_url'] = 'https://git.osuosl.org'

# String; ID of the 'GitLab Personal Access Token' credential the server
# config uses for API calls and webhook management (api scope, maintainer on
# the projects). Created out-of-band in the Jenkins UI, never via JCasC
# (which would wipe the credential store).
default['osl-jenkins']['cookbook_uploader']['gitlab_api_credential'] = 'gitlab-api-token'

# String; Full GitLab path of the private data_bags repo, deployed to the
# chef server by the data-bags multibranch pipeline.
default['osl-jenkins']['cookbook_uploader']['data_bags_project'] = 'osuosl-chef/data_bags'

# String; ID of the Jenkins SSH credential used to clone the data_bags repo.
# Created out-of-band in the Jenkins UI, never via JCasC.
default['osl-jenkins']['cookbook_uploader']['data_bags_credential'] = '5e204eb3-1907-4a36-8640-fa7ae3cacbf2'

###
### Attributes that are mainly for testing:
###

# Array<String>; If "nil", Jenkins automation will be set up for all repos in
# the above cookbook organization. If an array of repo names (not prefixed) is
# given, only they will have the automation set up. This is useful if you wish
# to test automation only on one or two repos before deploying to the entire
# GitHub organization.
default['osl-jenkins']['cookbook_uploader']['override_repos'] = nil

# Array<String>; If "nil", Jenkins automation will be remove up for all repos in
# the above cookbook organization. If an array of repo names (not prefixed) is
# given, only they will have the automation set up. This is useful if you wish
# to test automation only on one or two repos before deploying to the entire
# GitHub organization.
default['osl-jenkins']['cookbook_uploader']['override_archived_repos'] = nil

# Boolean; Whether to allow GitHub pushes to insecure URLs; useful for testing
# on a local Jenkins instance that doesn't have a valid SSL cert.
default['osl-jenkins']['cookbook_uploader']['github_insecure_hook'] = false

# Boolean; Whether to actually upload cookbooks to the Chef server; useful for
# testing if you don't actually have access to the Chef server. All other
# actions (e.g. merging and creating PRs) will still be performed.
default['osl-jenkins']['cookbook_uploader']['do_not_upload_cookbooks'] = false
