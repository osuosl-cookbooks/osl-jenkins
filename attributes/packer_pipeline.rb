default['osl-jenkins']['packer_pipeline']['openstack_taster_version'] = '0.0.2'
default['packer']['version'] = '1.0.2'
default['osl-jenkins']['packer_pipeline']['packer_ppc64le'] = {
  'url_base' => "http://ftp.osuosl.org/pub/osl/openpower/packer/packer-v#{node['packer']['version']}-dev",
  'sha256sum' => '7faa5665cb5bd4e53f670b8dc1bfe83b1a71177d5a049840365967f0049897c3'
}
