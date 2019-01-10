default['osl-jenkins']['powerci']['docker_images'] = %w(
  osuosl/ubuntu-ppc64le:16.04
  osuosl/ubuntu-ppc64le:18.04
  osuosl/ubuntu-ppc64le-cuda:8.0
  osuosl/ubuntu-ppc64le-cuda:9.0
  osuosl/ubuntu-ppc64le-cuda:9.1
  osuosl/ubuntu-ppc64le-cuda:9.2
  osuosl/ubuntu-ppc64le-cuda:10.0
  osuosl/ubuntu-ppc64le-cuda:8.0-cudnn6
  osuosl/ubuntu-ppc64le-cuda:9.0-cudnn7
  osuosl/ubuntu-ppc64le-cuda:9.1-cudnn7
  osuosl/ubuntu-ppc64le-cuda:9.2-cudnn7
  osuosl/ubuntu-ppc64le-cuda:10.0-cudnn7
  osuosl/debian-ppc64le:9
  osuosl/debian-ppc64le:buster
  osuosl/debian-ppc64le:unstable
  osuosl/fedora-ppc64le:28
  osuosl/fedora-ppc64le:29
  osuosl/centos-ppc64le:7
  osuosl/centos-ppc64le-cuda:8.0
  osuosl/centos-ppc64le-cuda:9.0
  osuosl/centos-ppc64le-cuda:9.1
  osuosl/centos-ppc64le-cuda:9.2
  osuosl/centos-ppc64le-cuda:8.0-cudnn6
  osuosl/centos-ppc64le-cuda:9.0-cudnn7
  osuosl/centos-ppc64le-cuda:9.1-cudnn7
  osuosl/centos-ppc64le-cuda:9.2-cudnn7
)
default['osl-jenkins']['powerci']['docker']['memory_limit'] = 'null'
default['osl-jenkins']['powerci']['docker']['memory_swap'] = 'null'
default['osl-jenkins']['powerci']['docker']['cpu_shared'] = 'null'
default['osl-jenkins']['powerci']['docker_public_key'] = ''
