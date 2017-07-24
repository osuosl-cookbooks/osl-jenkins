#!/opt/chef/embedded/bin/ruby
require_relative '../lib/packer_pipeline'

puts PackerPipeline.start.to_json
