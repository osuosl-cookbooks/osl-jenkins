default['osl-jenkins']['site_pr_builder'] = {
  'bin_path' => ::File.join(node['jenkins']['master']['home'], 'bin'),
  'lib_path' => ::File.join(node['jenkins']['master']['home'], 'lib'),
  'sites_to_build' => {
    'beaver-barcamp-pelican' => 'https://github.com/osuosl/beaver-barcamp-pelican.git',
    'cass-pelican' => 'https://github.com/osu-cass/cass-pelican.git',
    'osuosl-pelican' => 'https://github.com/osuosl/osuosl-pelican.git',
    'wiki' => 'https://github.com/osuosl/wiki.git',
    'docs' => 'https://github.com/osuosl/docs.git'
  },
  'credentials' => {
    'trigger_token' => nil,
    'github_user' => nil,
    'github_token' => nil
  }
}
