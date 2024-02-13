control 'bumpzone' do
  describe http('https://127.0.0.1/job/bumpzone/', ssl_verify: false) do
    its('status') { should eq 200 }
    its('headers.X-Jenkins') { should_not eq nil }
  end

  describe file('/var/lib/jenkins/lib/bumpzone.rb') do
    its('mode') { should cmp 0440 }
    its('owner') { should eq 'jenkins' }
    its('group') { should eq 'jenkins' }
  end

  describe file('/var/lib/jenkins/bin/bumpzone.rb') do
    its('mode') { should cmp 0550 }
    its('owner') { should eq 'jenkins' }
    its('group') { should eq 'jenkins' }
  end

  describe command('/opt/cinc/embedded/bin/gem list --local') do
    %w(
      faraday-http-cache
      git
      octokit
    ).each do |g|
      its('stdout') { should match(/^#{g}/) }
    end
  end
end
