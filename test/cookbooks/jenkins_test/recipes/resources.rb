osl_jenkins_private_key_credentials 'default' do
  username 'username'
  private_key 'private_key'
end

osl_jenkins_client_cert_credentials 'default' do
  cert 'cert'
  key 'key'
  chain 'chain'
end

osl_jenkins_password_credentials 'default' do
  password 'password'
end

osl_jenkins_job 'inline' do
  script 'script'
end

osl_jenkins_job 'template' do
  template true
  variables(default: 'default')
end

osl_jenkins_job 'file' do
  file true
end

osl_jenkins_plugin 'github'
