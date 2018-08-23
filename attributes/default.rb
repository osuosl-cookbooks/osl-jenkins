###
### Attributes that you really should put in a databag instead:
###

# It's not secure to store the following as attributes; these are only here for documentation and are usually set by
# test kitchen from environment variables for testing. In production, store credentials in the secrets databag specified
# below.
#
# user: (String) The GitHub username of the user associated with the API token.  This is necessary because regular git
#       pull/push operations (as opposed to API operations, which just require the token) require a username/password or
#       SSH key. You can, however, use an API token in place of a password, and since we already have an API token, we
#       just need to username to go with it.
# token: (String) A GitHub API token that has read and write permissions to the repos it needs
#
# default['osl-jenkins']['credentials']['git'] = {
#   'cookbook_uploader' => {
#     user: 'ramereth',
#     token: 'token_password'
#   }
# }
default['osl-jenkins']['credentials']['git'] = []

# user: (String) The username jenkins should ssh as using this key
# private_key: (String) An openssh private key
# password: (String) A password for the private key (optional)
#
# default['osl-jenkins']['credentials']['ssh'] = {
#   'cookbook_uploader' => {
#     user: 'ramereth',
#     private_key: 'private rsa key',
#     passphrase: 'passphrase for rsa key'
#   }
# }
default['osl-jenkins']['credentials']['ssh'] = []

# user: (String)  If Jenkins has username/password security enabled (as opposed to being public and not requiring a
#                 login), you must specify a Jenkins user that has permission to create jobs since the Jenkins cookbook
#                 uses the Jenkins API locally to configure new jobs, and so needs credentials.
# api_token (String) Jenkins user api token for authentication with Jenkins server.
# trigger_token: (String) A random string that is used to allow GitHub to send pushes to Jenkins. Jenkins' job trigger
#                 URLs are publicly accessible, so Jenkins will ignore POSTs to them unless the correct trigger_token is
#                 specified. You can generate a random string easily with a command such as `pwgen -s 20 1`.
#
# default['osl-jenkins']['credentials']['jenkins'] = {
#   'cookbook_uploader' => {
#     user: 'jenkins',
#     api_token: 'jenkins_api_token',
#     trigger_token: 'trigger_token'
#   }
# }
default['osl-jenkins']['credentials']['jenkins'] = []

###
### Attributes that you probably don't need to change:
###

# String; The name of the databag to use.
default['osl-jenkins']['secrets_databag'] = 'osl_jenkins'

# String; The name of the databag item to use.
default['osl-jenkins']['secrets_item'] = 'secrets'

###
### Attributes that can be set separately in each recipe
###

# String: The names of chef gems to install
default['osl-jenkins']['gems'] = []

# String: The paths of Jenkins binaries and libraries
default['osl-jenkins']['bin_path'] =  ::File.join(node['jenkins']['master']['home'], 'bin')
default['osl-jenkins']['lib_path'] = ::File.join(node['jenkins']['master']['home'], 'lib')
