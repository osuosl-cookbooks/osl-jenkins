require 'serverspec'

set :backend, :exec

RSpec.configure do |config|
  config.before(:all) do
    config.path = '/opt/chef/embedded/bin:/usr/local/sbin:
                   /usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
  end
end
