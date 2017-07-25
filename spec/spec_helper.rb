require 'chefspec'
require 'chefspec/berkshelf'
require_relative 'support/matchers'

ChefSpec::Coverage.start! { add_filter 'osl-jenkins' }

CENTOS_7_OPTS = {
  platform: 'centos',
  version: '7.2.1511',
  file_cache_path: '/var/chef/cache'
}

CENTOS_6_OPTS = {
  platform: 'centos',
  version: '6.7',
  file_cache_path: '/var/chef/cache'
}

ALL_PLATFORMS = [
  CENTOS_6_OPTS,
  CENTOS_7_OPTS
]

RSpec.configure do |config|
  config.log_level = :fatal
end

shared_context 'common_stubs' do
  before do
    allow(Chef::EncryptedDataBagItem).to receive(:load)
      .with('osl_jenkins', 'secrets')
      .and_raise(Net::HTTPServerException.new(
                   'osl_jenkins databag not found',
                   Net::HTTPResponse.new('1.1', '404', '')
      ))
  end
end

shared_context 'data_bag_stubs' do
  before do
    stub_data_bag_item('users','alfred').and_return(
      'id': 'alfred',
      'ssh_keys': [
        'test_ssh_key'
      ]
    )

    allow(Chef::EncryptedDataBagItem).to receive(:load)
      .with('osl_jenkins','packer_pipeline_creds')
      .and_return(
        'id': 'packer_pipeline_creds'
      )
      .and_raise(Net::HTTPServerException.new(
                   'osl_jenkins databag not found',
                   Net::HTTPResponse.new('1.1', '404', '')
      ))
  end
end
shared_context 'cookbook_uploader' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:set_up_github_push)
  end
end
