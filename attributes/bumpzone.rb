default['osl-jenkins']['bumpzone'] = {
  'bin_path' => ::File.join(node['jenkins']['master']['home'], 'bin'),
  'lib_path' => ::File.join(node['jenkins']['master']['home'], 'lib'),
  'secrets_databag' => 'osl_jenkins',
  'secrets_item' => 'bumpzone',
  'github_url' => 'https://github.com/osuosl/zonefiles.git',
  'credentials' => {
    'trigger_token' => nil,
    'github_user' => nil,
    'github_token' => nil
  }
}
