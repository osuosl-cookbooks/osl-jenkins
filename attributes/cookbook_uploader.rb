default['osl-jenkins']['cookbook_uploader']['org'] = 'osuosl-cookbooks'
# Use the following list of repo names rather than searching the given org.
default['osl-jenkins']['cookbook_uploader']['override_repos'] = None
default['osl-jenkins']['cookbook_uploader']['secrets_databag'] = 'osl_jenkins'
default['osl-jenkins']['cookbook_uploader']['secrets_item'] = 'github_secrets'
default['osl-jenkins']['cookbook_uploader']['scripts_path'] = \
  ::File.join(node['jenkins']['master']['home'], 'bin')
default['osl-jenkins']['cookbook_uploader']['github_insecure_hook'] = false

# It's not secure to store these as attributes; these are only here for
# documentation and are usually set by test kitchen from environment variables
# for testing. In production, store credentials in the secrets databag.
default['osl-jenkins']['cookbook_uploader']['credentials']['github_user'] = ''
default['osl-jenkins']['cookbook_uploader']['credentials']['github_token'] = ''
default['osl-jenkins']['cookbook_uploader']['credentials']['trigger_token'] = ''
default['osl-jenkins']['cookbook_uploader']['credentials']['jenkins_user'] = ''
default['osl-jenkins']['cookbook_uploader']['credentials']['jenkins_pass'] = ''
