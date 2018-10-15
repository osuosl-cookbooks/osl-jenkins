require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'support/matchers'

ChefSpec::Coverage.start! { add_filter 'osl-jenkins' }

CENTOS_7_OPTS = {
  platform: 'centos',
  version: '7.2.1511',
  file_cache_path: '/var/chef/cache',
}

CENTOS_6_OPTS = {
  platform: 'centos',
  version: '6.7',
  file_cache_path: '/var/chef/cache',
}

ALL_PLATFORMS = [
  CENTOS_6_OPTS,
  CENTOS_7_OPTS,
]

RSpec.configure do |config|
  config.log_level = :fatal
end

shared_context 'common_stubs' do
  before do
    stub_data_bag_item('osl_jenkins', 'secrets')
      .and_raise(Net::HTTPServerException.new(
                   'Not Found',
                   Net::HTTPResponse.new('1.1', '404', '')
      ))
    stub_command("chef gem list -i -v '< 2.0.0' netaddr").and_return(true)
    stub_command("chef gem list -i -v '>= 2.0.0' netaddr").and_return(false)
    stub_command('chef gem list -i kitchen-transport-rsync').and_return(false)
    stub_command("chef gem list -i -v '= 2.7.5' rubygems")
  end
end

shared_context 'data_bag_stubs' do
  before do
    stub_data_bag_item('users', 'alfred').and_return(
      id: 'alfred',
      ssh_keys: [
        'test_ssh_key',
      ]
    )

    stub_data_bag_item('osl_jenkins', 'packer_pipeline_creds')
      .and_return(
        id: 'packer_pipeline_creds'
      )

    stub_data_bag_item('osl_jenkins', 'jenkins1')
      .and_return(
        id: 'jenkins1',
        'jenkins' => {
          'packer_pipeline' => {
            'public_key' => 'public key for openstack_taster goes here',
            'private_key' => 'private key for openstack_taster goes here',
          },
        },
        'git' => {
          'packer_pipeline' => {
            'user' => 'osuosl-manatee',
            'token' => 'FAKE_TOKEN',
          },
        }
      )
  end
end
shared_context 'cookbook_uploader' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:set_up_github_push)
  end
end
