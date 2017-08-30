#!/opt/chef/embedded/bin/ruby
require_relative '../lib/packer_pipeline'
require 'json'
require 'optparse'

options = {}

parser = OptionParser.new do |opts|
  opts.banner = """
        Usage: #{$0} -p PAYLOAD_JSON_FILE -f FINAL_RESULTS_FILE
        You can either pass the PAYLOAD_JSON_FILE to process and begin the pipeline processing
        OR the FINAL_RESULTS_FILE to send back to GitHub
  """

  opts.separator('')
  opts.on('-p PAYLOAD_JSON_FILE',
          '--payload_file PAYLOAD_JSON_FILE',
          'Specify the JSON payload to process.') do |p|
    options[:payload_json_file] = p
  end

  opts.on('-f FINAL_RESULTS_FILE',
          '--final_results_file FINAL_RESULTS_FILE',
          'Specify the JSON file containing the final results of pipeline processing.') do |f|
    options[:final_results_file] = f
  end

  opts.on_tail('-h', '--help', 'Prints this help text') do
    puts opts
    exit
  end
end

parser.parse! ARGV

puts options

if !options.key?(:payload_json_file) &&
   !options.key?(:final_results_file)

  puts "Either you must pass the PAYLOAD_JSON_FILE or the FINAL_RESULTS_FILE!"
  exit 1
end


if options[:final_results_file]
  if File.readable? options[:final_results_file]
    final_results = JSON.parse(File.read(options[:final_results_file]))
    PackerPipeline.new().set_commit_status(final_results)
    exit 0
  else
    puts "Final results file #{options[:final_results_file]} is not readable!"
    exit 2
  end
end

if options[:payload_json_file]
  if File.readable? options[:payload_json_file]
    payload = JSON.parse(File.read(options[:payload_json_file]))
    PackerPipeline.new().process_payload(payload).to_json
    exit 0
  else
    puts "Payload JSON file #{options[:payload_json_file]} is not readable!"
    exit 2
  end
end
