default['osl-jenkins']['github_comment'] = {
  'bin_path' => ::File.join(node['jenkins']['master']['home'], 'bin'),
  'lib_path' => ::File.join(node['jenkins']['master']['home'], 'lib'),
  'secrets_databag' => 'osl_jenkins',
  'secrets_item' => 'github_comment',
  'credentials' => {
    'trigger_token' => nil,
    'github_user' => nil,
    'github_token' => nil
  }
}
