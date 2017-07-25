require 'serverspec'
require 'spec_helper'

describe file('/home/alfred/.gitconfig') do
  it { should exist }
  it { should be_a_file }
  it do
    should contain(
      'pr  = "!f() { git fetch -fu ${2:-$(git remote |grep ^upstream || echo origin)} \
      refs/pull/$1/head:pr/$1 && git checkout pr/$1; }; f"'
    ).after(/[alias]/)
  end
end

describe file('/home/alfred/workspace') do
  it { should be_a_directory }
  it { should exist }
  it { should be_owned_by 'alfred' }
  it { should be_grouped_into 'alfred' }
end

describe file('/usr/local/bin/packer') do
  it { should be_a_file }
  it { should be_executable }
end

describe file('/home/alfred/openstack_credentials.json') do
  it { should be_a_file }
  it { should be_owned_by 'alfred' }
  it { should be_grouped_into 'alfred' }
  it { should be_grouped_into 'alfred' }
  it { should be_mode 600 }
end

describe package('qemu-kvm') do
  it { should be_installed }
end

describe file('/opt/chef/embedded/bin/openstack_taster') do
  it { should be_a_file }
  it { should be_executable }
end
