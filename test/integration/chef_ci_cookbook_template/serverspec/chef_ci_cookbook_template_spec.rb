require 'serverspec'

set :backend, :exec

RSpec.configure do |config|
  config.before(:all) do
    config.path = '/opt/chef/embedded/bin:/usr/local/sbin:
                   /usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end
end

describe package('foodcritic') do
  it { should be_installed.by('gem').with_version('4.0.0') }
end

describe package('rubocop') do
  it { should be_installed.by('gem').with_version('0.30.1') }
end
