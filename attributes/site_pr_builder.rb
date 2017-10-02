default['osl-jenkins']['site_pr_builder'] = {
  'bin_path' => ::File.join(node['jenkins']['master']['home'], 'bin'),
  'lib_path' => ::File.join(node['jenkins']['master']['home'], 'lib'),
  'sites_to_build' => {
    'beaver-barcamp-pelican' => 'osuosl',
    'osuosl-pelican' => 'osuosl',
    'wiki' => 'osuosl'
  },
  'credentials' => {
    'trigger_token' => nil,
    'github_user' => nil,
    'github_token' => nil
  }
}
