jdk_ver = os.release.to_i >= 8 ? '21' : '11'

control 'controller' do
  %w(
    dejavu-sans-fonts
    fontconfig
    jenkins
    haproxy
  ).each do |p|
    describe package p do
      it { should be_installed }
    end
  end

  %w(
    jenkins
    haproxy
  ).each do |s|
    describe service s do
      it { should be_enabled }
      it { should be_running }
    end
  end

  describe package "java-#{jdk_ver}-openjdk-headless" do
    it { should be_installed }
  end

  %w(80 443 8080).each do |p|
    describe port(p) do
      it { should be_listening }
    end
  end

  describe http('http://127.0.0.1/') do
    its('status') { should eq 302 }
    its('headers.Location') { should match(%r{https://127.0.0.1/}) }
  end

  describe http('https://127.0.0.1/about/', ssl_verify: false) do
    its('headers.X-Jenkins') { should match(/2.[0-9]+/) }
  end
end
