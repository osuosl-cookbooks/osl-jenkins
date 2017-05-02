require 'serverspec'
set :backend, :exec

shared_examples_for 'jenkins_server' do
  describe package('java-1.8.0-openjdk') do
    it { should be_installed }
  end

  describe package('jenkins') do
    it { should be_installed.with_version('2.46.2-1.1') }
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
    its(:stdout) { should match(/Jenkins 2.46.2/) }
  end
end
