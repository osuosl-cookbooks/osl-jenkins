default['osl-jenkins']['powerci']['docker_images'] = %w(
  osuosl/ubuntu-ppc64le:20.04
  osuosl/ubuntu-ppc64le:22.04
  osuosl/ubuntu-ppc64le:24.04
  osuosl/debian-ppc64le:11
  osuosl/debian-ppc64le:12
  osuosl/debian-ppc64le:buster
  osuosl/debian-ppc64le:unstable
  osuosl/debian-ppc64le:sid
)
default['osl-jenkins']['powerci']['docker']['memory_limit'] = 'null'
default['osl-jenkins']['powerci']['docker']['memory_swap'] = 'null'
default['osl-jenkins']['powerci']['docker']['cpu_shared'] = 'null'
default['osl-jenkins']['powerci']['docker_public_key'] = ''
