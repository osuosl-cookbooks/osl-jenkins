default['osl-jenkins']['powerci']['docker_images'] = %w(
  osuosl/ubuntu-ppc64le:16.04
  osuosl/debian-ppc64le:9
  osuosl/fedora-ppc64le:26
  osuosl/centos-ppc64le:7
)
default['osl-jenkins']['powerci']['docker']['memory_limit'] = 'null'
default['osl-jenkins']['powerci']['docker']['memory_swap'] = 'null'
default['osl-jenkins']['powerci']['docker']['cpu_shared'] = 'null'
default['osl-jenkins']['powerci']['docker_public_key'] = ''
