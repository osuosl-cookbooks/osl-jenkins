default['osl-jenkins']['packer_pipeline'] = {
  'bin_path' => ::File.join(node['jenkins']['master']['home'], 'bin'),
  'lib_path' => ::File.join(node['jenkins']['master']['home'], 'lib'),
  'secrets_databag' => 'osl_jenkins',
  'secrets_item' => 'packer_pipeline'
}
