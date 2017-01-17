#!/opt/chef/embedded/bin/ruby

# Takes a JSON payload from a Github PR issue webhook from stdin

require 'git'
require 'json'
require 'octokit'

$commit_msg = "\n\n"

def _regex(file, regex)
  !!(file =~ regex)
end

def bump_zone(zone_file)
  soa_oneline_regex = /(^[\w\d\.-_]+\s+[\d]+\s+IN\s+SOA.*[\w\d\.-_]+)\s+(\d{10})\s+([\d]+\s+[\d]+\s+[\d]+\s+[\d]+)/
  soa_multiline_regex = /(^[\w\d\.-_]+\s+IN\s+SOA\s+[\w\d\.-_]+\s+[\w\d\.-_]+\s+\(\n\s+)(\d{10})(.*\n.*\n.*\n.*\n.*\n\s+\))/
  new_serial = nil
  zone = ::File.read(zone_file)
  if _regex(zone, soa_oneline_regex)
    soa_oneline = true
  elsif _regex(zone, soa_multiline_regex)
    soa_oneline = false
  else
    puts 'no soa found!'
    exit 1
  end
  zone_new = zone.gsub(soa_oneline ? soa_oneline_regex : soa_multiline_regex) do
    before_serial = Regexp.last_match(1)
    cur_serial = Regexp.last_match(2).to_i
    after_serial = Regexp.last_match(3)
    new_serial = Time.new.strftime('%Y%m%d00').to_i
    counter = cur_serial.to_s.match(/\d{2}$/)
    if counter.to_s =~ /99/
      puts 'error!'
      exit 1
    end
    new_serial = 1 + cur_serial if new_serial <= cur_serial
    $commit_msg << "Bump #{zone_file} from #{cur_serial} to #{new_serial}\n"
    if soa_oneline
      "#{before_serial} #{new_serial} #{after_serial}"
    else
      "#{before_serial}#{new_serial}#{after_serial}"
    end
  end

  ::File.write(zone_file, zone_new)
end

d = JSON.load(STDIN.read)

unless d['action'] == 'closed' && d['pull_request']['merged'] == true
  puts 'This isn\'t a merged request, so don\'t do anything'
  exit 0
end

# Get PR object
github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
repo_name = d['repository']['name']
repo_path = d['repository']['full_name']
issue_number = d['number']

files = github.pull_request_files(repo_path, issue_number)
files.each do |f|
  bump_zone(f.filename) if f.filename =~ /^db\..*/
end

# Set up the git gem
git = Git.open('.')

# Commit changes
git.add(all: true)
git.commit("Automatically bumping zone serials#{$commit_msg}")
# Push back to Github
# git.push(git.remote('origin'), 'master')

# Notify master to update
