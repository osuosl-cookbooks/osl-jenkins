require 'serverspec'
require 'net/http'
require 'open-uri'
require 'uri'

set :backend, :exec

shared_examples_for 'jenkins_server' do
  # Copied from jenkins cookbook helper library
  begin
    open('https://localhost/whoAmI/', ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE)
  rescue SocketError,
         Errno::ECONNREFUSED,
         Errno::ECONNRESET,
         Errno::ENETUNREACH,
         Errno::EADDRNOTAVAIL,
         Timeout::Error,
         OpenURI::HTTPError => e
    # If authentication has been enabled, the server will return an HTTP
    # 403. This is "OK", since it means that the server is actually
    # ready to accept requests.
    return if e.message =~ /^403/

    puts "Jenkins is not accepting requests - #{e.message}"
    sleep(0.5)
    retry
  end

  describe package('java-1.8.0-openjdk') do
    it { should be_installed }
  end

  describe package('jenkins') do
    it { should be_installed.with_version('2.164.2-1.1') }
  end

  describe command('yum versionlock') do
    its(:stdout) { should match(/^0:jenkins-2.164.2-1.1.x86_64$/) }
  end

  %w(80 443 8080).each do |p|
    describe port(p) do
      it { should be_listening }
    end
  end

  describe command('curl -v http://localhost/ 2>&1') do
    its(:stdout) { should match(%r{HTTP/1.1 302 Found}) }
    its(:stdout) { should match(%r{Location: https://localhost/}) }
  end

  describe command('curl -k https://localhost/about/') do
    its(:stdout) { should match(/Jenkins 2.164.2/) }
  end
end
