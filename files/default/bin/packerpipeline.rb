#!/opt/chef/embedded/bin/ruby
require_relative '../lib/packerpipeline'

puts PackerPipeline.start.to_json
