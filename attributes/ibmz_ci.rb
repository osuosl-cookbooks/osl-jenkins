default['osl-jenkins']['ibmz_ci']['docker_images'] = %w(
  osuosl/ubuntu-s390x:16.04
  osuosl/ubuntu-s390x:18.04
  osuosl/debian-s390x:9
  osuosl/debian-s390x:buster
  osuosl/debian-s390x:unstable
  osuosl/fedora-s390x:28
  osuosl/fedora-s390x:29
)
default['osl-jenkins']['ibmz_ci']['docker']['memory_limit'] = 'null'
default['osl-jenkins']['ibmz_ci']['docker']['memory_swap'] = 'null'
default['osl-jenkins']['ibmz_ci']['docker']['cpu_shared'] = 'null'
default['osl-jenkins']['ibmz_ci']['docker_public_key'] = ''
