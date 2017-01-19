#!/opt/chef/embedded/bin/ruby

# Takes a JSON payload from a Github PR issue webhook from stdin

require 'git'
require 'json'
require 'octokit'

# Library to bump DNS zones
class BumpZone
  @commit_msg = "\n\n"
  @soa_oneline = nil
  ONELINE_REGEX = /(^[\w\d\.-_]+\s+[\d]+\s+IN\s+SOA.*[\w\d\.-_]+\s+)(\d{10})(\s+[\d]+\s+[\d]+\s+[\d]+\s+[\d]+)/
  MULTILINE_REGEX = /(^[\w\d\.-_]+\s+IN\s+SOA\s+[\w\d\.-_]+\s+[\w\d\.-_]+\s+\(\n\s+)(\d{10})(.*\n.*\n.*\n.*\n.*\n\s+\))/

  class << self
    attr_reader :commit_msg
  end

  def self.add_commit_msg(msg)
    @commit_msg << msg
  end

  def self.regex(file, regex)
    !(file !~ regex)
  end

  def self.zone_type(zone)
    if regex(zone, ONELINE_REGEX)
      @soa_oneline = true
    elsif regex(zone, MULTILINE_REGEX)
      @soa_oneline = false
    else
      puts 'no soa found!'
      exit 1
    end
  end

  def self.print_soa(before_serial, serial, after_serial)
    "#{before_serial}#{serial}#{after_serial}"
  end

  def self.counter(cur_serial)
    counter = cur_serial.to_s.match(/\d{2}$/)
    puts 'error!' if counter.to_s =~ /99/
  end

  def self.new_serial(zone_file, filename)
    cur_serial = zone_file.match(@soa_oneline ? ONELINE_REGEX : MULTILINE_REGEX)[2].to_i
    new_serial = Time.new.strftime('%Y%m%d00').to_i
    BumpZone.counter(cur_serial)
    new_serial = 1 + cur_serial.to_i if new_serial <= cur_serial.to_i
    BumpZone.add_commit_msg("Bump #{filename} from #{cur_serial} to #{new_serial}\n")
    new_serial.to_i
  end

  def self.bump(zone_file)
    zone = ::File.read(zone_file)
    BumpZone.zone_type(zone)
    new_serial = BumpZone.new_serial(zone, zone_file)
    zone_new = zone.gsub(@soa_oneline ? ONELINE_REGEX : MULTILINE_REGEX) do
      BumpZone.print_soa(Regexp.last_match(1), new_serial, Regexp.last_match(3))
    end

    ::File.write(zone_file, zone_new)
  end
end

d = JSON.parse(STDIN.read)

unless d['action'] == 'closed' && d['pull_request']['merged'] == true
  puts 'This isn\'t a merged request, so don\'t do anything'
  exit 0
end

# Get PR object
github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
repo_path = d['repository']['full_name']
issue_number = d['number']

files = github.pull_request_files(repo_path, issue_number)
files.each do |f|
  BumpZone.bump(f.filename) if f.filename =~ /^db\..*/
end

# Set up the git gem
git = Git.open('.')

# Commit changes
git.add(all: true)
git.commit("Automatically bumping zone serials#{BumpZone.commit_msg}")
# Push back to Github
# git.push(git.remote('origin'), 'master')

# Notify master to update
