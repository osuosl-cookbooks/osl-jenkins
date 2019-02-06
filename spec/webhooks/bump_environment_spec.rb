require 'rspec'
require 'rspec/mocks'
require 'tempfile'
require 'pathname'
require_relative '../../files/default/lib/bump_environments'

module SpecHelper
  def fixture_path(name)
    File.join(File.expand_path('../../fixtures', __FILE__), name)
  end

  def open_fixture(name)
    File.read(fixture_path(name))
  end

  def open_json(name)
    JSON.parse(open_fixture(name))
  end

  def tempfile(file)
    tempfile = Tempfile.new("#{Pathname.new(file).basename}-rspec")
    tempfile.write(::File.read(file))
    tempfile.rewind
    tempfile
  end
end

RSpec.configure do |c|
  c.include SpecHelper
end

describe BumpEnvironments do
  it 'verify chef env'
    BumpEnvironments.verify_chef_env
    expect(self).to receive(:verify_default_chef_env)
    expect(self).to receive(:verify_all_chef_env)
  end

  context 'include default chef env word'
     
  end
end
