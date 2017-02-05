require 'chefspec'
require 'chefspec/berkshelf'

ChefSpec::Coverage.start! { add_filter 'osl-jenkins' }

CENTOS_7_OPTS = {
  platform: 'centos',
  version: '7.2.1511'
}.freeze

CENTOS_6_OPTS = {
  platform: 'centos',
  version: '6.7'
}.freeze

ALL_PLATFORMS = [
  CENTOS_6_OPTS,
  CENTOS_7_OPTS
].freeze

RSpec.configure do |config|
  config.log_level = :fatal
end

shared_context 'cookbook_uploader' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:set_up_github_push)
    allow(Chef::EncryptedDataBagItem).to receive(:load).with('osl_jenkins', 'cookbook_uploader_secrets')
      .and_return(
        jenkins_private_key: 'private_key',
        github_user: 'manatee',
        github_token: 'github_token',
        trigger_token: 'trigger_token',
        jenkins_user: 'jenkins',
        jenkins_api_token: 'jenkins_api_token'
      )
  end
end
