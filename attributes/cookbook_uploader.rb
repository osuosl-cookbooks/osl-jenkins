default['osl-jenkins']['cookbook_uploader']['org'] = 'osuosl-cookbooks'
default['osl-jenkins']['cookbook_uploader']['chef_repo'] = 'osuosl/chef-repo'
# Use the following list of repo names rather than searching the given org.
default['osl-jenkins']['cookbook_uploader']['override_repos'] = nil
default['osl-jenkins']['cookbook_uploader']['secrets_databag'] = 'osl_jenkins'
default['osl-jenkins']['cookbook_uploader']['secrets_item'] = 'secrets'
default['osl-jenkins']['cookbook_uploader']['scripts_path'] = \
  ::File.join(node['jenkins']['master']['home'], 'bin')
default['osl-jenkins']['cookbook_uploader']['github_insecure_hook'] = false
default['osl-jenkins']['cookbook_uploader']['do_not_upload_cookbooks'] = false
default['osl-jenkins']['cookbook_uploader']['authorized_users'] = []
default['osl-jenkins']['cookbook_uploader']['authorized_orgs'] = []
default['osl-jenkins']['cookbook_uploader']['authorized_teams'] = []

# It's not secure to store these as attributes; these are only here for
# documentation and are usually set by test kitchen from environment variables
# for testing. In production, store credentials in the secrets databag.
default['osl-jenkins']['cookbook_uploader']['credentials']['github_user'] = ''
default['osl-jenkins']['cookbook_uploader']['credentials']['github_token'] = ''
default['osl-jenkins']['cookbook_uploader']['credentials']['trigger_token'] = ''
default['osl-jenkins']['cookbook_uploader']['credentials']['jenkins_user'] = ''
default['osl-jenkins']['cookbook_uploader']['credentials']['jenkins_pass'] = ''
