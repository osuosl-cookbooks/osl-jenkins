default['osl-jenkins']['cookbook_uploader']['org'] = 'osuosl-cookbooks'
default['osl-jenkins']['cookbook_uploader']['secrets_databag'] = 'osl_jenkins'
default['osl-jenkins']['cookbook_uploader']['secrets_item'] = 'github_secrets'
default['osl-jenkins']['cookbook_uploader']['scripts_path'] = \
  ::File.join('/home',
              node['jenkins']['master']['user'],
              'bin')

# It's not secure to store these as attributes; these are only here for
# documentation and are usually set by test kitchen from environment variables
# for testing. In production, store credentials in the secrets databag.
default['osl-jenkins']['cookbook_uploader']['credentials']['github_user'] = ''
default['osl-jenkins']['cookbook_uploader']['credentials']['github_token'] = ''
