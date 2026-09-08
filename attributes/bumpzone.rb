default['osl-jenkins']['bumpzone'] = {
  'secrets_databag' => 'osl_jenkins',
  'secrets_item' => 'bumpzone',
  # org/name of the DNS zone file repo. Split for the multibranch job's
  # repoOwner/repository, the way cookbook_uploader does with chef_repo.
  'repo' => 'osuosl/zonefiles',
  'github_url' => 'https://github.com/osuosl/zonefiles.git',
  # Branch the zone-bumper and update-zonefiles jobs read their Jenkinsfiles
  # from. The pipelines themselves act on the pull request's base branch.
  'pipelines_branch' => 'master',
  'dns_primary' => 'dns_primary',
  'credentials' => {
    'trigger_token' => nil,
    'github_user' => nil,
    'github_token' => nil,
  },
}
