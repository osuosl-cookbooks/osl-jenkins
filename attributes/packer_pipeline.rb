default['osl-jenkins']['packer_pipeline']['openstack_taster_version'] = '1.0.1'
default['osl-jenkins']['packer_pipeline']['packer_ppc64le'] = {
  'version' => '1.0.3-dev',
  'url_base' => 'http://ftp.osuosl.org/pub/osl/openpower/packer/packer-v1.0.3-dev',
  'sha256sum' => '7faa5665cb5bd4e53f670b8dc1bfe83b1a71177d5a049840365967f0049897c3'
}

default['osl-jenkins']['packer_pipeline'] = {
  'bin_path' => ::File.join(node['jenkins']['master']['home'], 'bin'),
  'lib_path' => ::File.join(node['jenkins']['master']['home'], 'lib'),
}
