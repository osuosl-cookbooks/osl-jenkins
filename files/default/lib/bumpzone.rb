#!/opt/chef/embedded/bin/ruby
require 'git'
require 'json'
require 'octokit'
require 'faraday-http-cache'

# Github API caching
stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::HttpCache, serializer: Marshal, shared_cache: false
  builder.use Octokit::Response::RaiseError
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack

# Library to bump DNS zones
class BumpZone
  @commit_msg = "\n\n"
  @warning_msg = "Warning:\n\n"
  @warning = false
  ONELINE_REGEX = /(^[\w\d\.\-]+\s+[\d]+\s+IN\s+SOA.*[\w\d\.\-]+\s+)(\d{10})(\s+[\d]+\s+[\d]+\s+[\d]+\s+[\d].*)/
  MULTILINE_REGEX =
    /(^[\w\d\.\-]+\s+IN\s+SOA\s+[\w\d\.\-]+\s+[\w\d\.\-]+\s+\((?:\s*;(?:[\s\w\d]*)?)?(?:\s*)?\n\s+)(\d{10})\
(.*\n.*\n.*\n.*\n.*\n\s+\))/

  class << self
    attr_reader :commit_msg
  end

  def self.add_commit_msg(msg)
    @commit_msg << msg
  end

  def self.add_warning_msg(msg)
    @warning = true
    @warning_msg << msg
  end

  def self.regex(file, regex)
    !(file !~ regex)
  end

  def self.soa_oneline?(zone)
    if regex(zone, ONELINE_REGEX)
      true
    elsif regex(zone, MULTILINE_REGEX)
      false
    end
  end

  def self.pr_merged(json)
    return unless json['action'] != 'closed' && json['pull_request']['merged'] != true
    puts 'Not a merged PR, skipping...'
    exit 0
  end

  def self.changed_files(json)
    github = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])
    repo_path = json['repository']['full_name']
    issue_number = json['number']
    github.pull_request_files(repo_path, issue_number)
  end

  def self.git_push
    # Set up the git gem
    git = Git.open('.')
    # Commit changes
    git.add(all: true)
    git.commit("Automatically bumping zone serials#{BumpZone.commit_msg}")
    git.push(git.remote('origin'), 'master')
  end

  def self.print_soa(before_serial, serial, after_serial)
    "#{before_serial}#{serial}#{after_serial}"
  end

  def self.max_count?(cur_serial)
    # Grab the last two digits of the serial which is the counter
    counter = cur_serial.to_s.match(/\d{2}$/)
    # Check if we've reached 99 which is the max allowed in one day
    counter.to_s.include? '99'
  end

  def self.new_serial(zone_file, filename)
    if zone_file.match(BumpZone.soa_oneline?(zone_file) ? ONELINE_REGEX : MULTILINE_REGEX)
      cur_serial = zone_file.match(BumpZone.soa_oneline?(zone_file) ? ONELINE_REGEX : MULTILINE_REGEX)[2].to_i
    else
      BumpZone.add_warning_msg("#{zone_file} does not contain an SOA\n")
      return nil
    end
    new_serial = Time.new.strftime('%Y%m%d00').to_i
    if BumpZone.max_count?(cur_serial)
      BumpZone.add_warning_msg("#{zone_file} has a max counter of #{Time.new.strftime('%Y%m%d99')}\n")
      return nil
    end
    new_serial = [cur_serial.to_i + 1, new_serial].max
    BumpZone.add_commit_msg("Bump #{filename} from #{cur_serial} to #{new_serial}\n")
    new_serial.to_i
  end

  def self.bump(zone_file)
    zone = ::File.read(zone_file)
    new_serial = BumpZone.new_serial(zone, zone_file)
    return if new_serial.nil?
    zone_new = zone.gsub(BumpZone.soa_oneline?(zone) ? ONELINE_REGEX : MULTILINE_REGEX) do
      BumpZone.print_soa(Regexp.last_match(1), new_serial, Regexp.last_match(3))
    end

    ::File.write(zone_file, zone_new)
  end

  def self.start
    d = JSON.parse(STDIN.read)
    BumpZone.pr_merged(d)
    BumpZone.changed_files(d).each do |f|
      BumpZone.bump(f.filename) if File.basename(f.filename) =~ /^db\..*/
    end
    BumpZone.git_push
  end
end
