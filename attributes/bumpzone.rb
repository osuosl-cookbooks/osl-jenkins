default['osl-jenkins']['bumpzone'] = {
  'secrets_databag' => 'osl_jenkins',
  'secrets_item' => 'bumpzone',
  'github_url' => 'https://github.com/osuosl/zonefiles.git',
  'dns_master' => 'dns_master',
  'credentials' => {
    'trigger_token' => nil,
    'github_user' => nil,
    'github_token' => nil,
  },
}
