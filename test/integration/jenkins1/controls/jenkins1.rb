control 'jenkins1' do
  describe package 'graphviz' do
    it { should be_installed }
  end

  describe command('/opt/cinc/embedded/bin/gem list --local') do
    %w(
      faraday-http-cache
      git
      octokit
    ).each do |g|
      its('stdout') { should match(/^#{g}/) }
    end
    its('stdout') { should_not match(/^faraday-http-cache \(2\.[6-9]|^faraday-http-cache \([3-9]/) }
    its('stdout') { should_not match(/^git \([4-9]\./) }
    its('stdout') { should_not match(/^octokit \(1[0-9]/) }
  end

  describe command("/opt/cinc/embedded/bin/ruby -e \"require 'octokit'\"") do
    its('exit_status') { should eq 0 }
  end
end
