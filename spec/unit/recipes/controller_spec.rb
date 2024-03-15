require_relative '../../spec_helper'

describe 'jenkins_test::controller' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.dup.merge(step_into: %w(
          osl_jenkins_config
          osl_jenkins_install
          osl_jenkins_service
        ))).converge(described_recipe)
      end
      include_context 'common_stubs'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to create_osl_jenkins_install('10.0.0.2').with(admin_address: 'noreply@example.org') }
      case p
      when CENTOS_7
        it { is_expected.to install_package 'java-11-openjdk-headless' }
      when ALMA_8
        it { is_expected.to install_package 'java-21-openjdk-headless' }
      end

      it do
        is_expected.to create_yum_repository('jenkins').with(
          baseurl: 'https://pkg.jenkins.io/redhat-stable',
          description: 'Jenkins-stable',
          gpgkey: 'https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key',
          gpgcheck: true
        )
      end
      it do
        is_expected.to install_package %w(
          dejavu-sans-fonts
          fontconfig
          jenkins
        )
      end
      it do
        is_expected.to create_certificate_manage('wildcard').with(
          cert_file: 'wildcard.pem',
          key_file: 'wildcard.key',
          chain_file: 'wildcard-bundle.crt',
          combined_file: true
        )
      end
      it { expect(chef_run.certificate_manage('wildcard')).to notify('haproxy_service[haproxy]').to(:restart) }
      it { is_expected.to include_recipe 'osl-git' }
      it { is_expected.to accept_osl_firewall_port 'http' }
      it { is_expected.to accept_osl_firewall_port 'haproxy' }
      it { is_expected.to include_recipe 'osl-haproxy::install' }
      it { is_expected.to include_recipe 'osl-haproxy::config' }
      it do
        is_expected.to create_haproxy_frontend('http').with(
          default_backend: 'jenkins',
          maxconn: 2000,
          extra_options: {
              'redirect' => 'scheme https if !{ ssl_fc }',
          }
        )
      end
      it { expect(chef_run.haproxy_frontend('http')).to notify('haproxy_service[haproxy]').to(:restart) }
      it do
        is_expected.to create_haproxy_frontend('https').with(
          default_backend: 'jenkins',
          maxconn: 2000,
          bind: '0.0.0.0:443 ssl crt /etc/pki/tls/certs/wildcard.pem'
        )
      end
      it { expect(chef_run.haproxy_frontend('https')).to notify('haproxy_service[haproxy]').to(:restart) }
      it do
        is_expected.to create_haproxy_backend('jenkins').with(
          server: [ 'jenkins 127.0.0.1:8080 check' ],
          option: %w(forwardfor),
          extra_options: {
            'http-request' => [
              'set-header X-Forwarded-Port %[dst_port]',
              'add-header X-Forwarded-Proto https if { ssl_fc }',
              'set-header X-Forwarded-Host %[req.hdr(Host)]',
            ],
          }
        )
      end
      it { expect(chef_run.haproxy_backend('jenkins')).to notify('haproxy_service[haproxy]').to(:restart) }
      it do
        is_expected.to create_remote_file('/opt/jenkins-plugin-manager.jar').with(
          source: 'https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download/2.12.15/jenkins-plugin-manager-2.12.15.jar'
        )
      end
      it do
        is_expected.to create_cookbook_file('/usr/local/bin/jenkins-plugin-cli').with(
          cookbook: 'osl-jenkins',
          mode: '0755'
        )
      end
      it do
        is_expected.to create_cookbook_file('/var/lib/jenkins/.gitconfig').with(
          cookbook: 'osl-jenkins',
          source: 'gitconfig',
          owner: 'jenkins',
          group: 'jenkins'
        )
      end
      it { is_expected.to create_directory('/var/lib/jenkins/bin').with(owner: 'jenkins', group: 'jenkins') }
      it { is_expected.to create_directory('/var/lib/jenkins/lib').with(owner: 'jenkins', group: 'jenkins') }
      it do
        is_expected.to create_directory('/var/lib/jenkins/casc_configs/groovy').with(
          user: 'jenkins',
          group: 'jenkins',
          mode: '0700',
          recursive: true
        )
      end
      it do
        is_expected.to create_directory('/var/lib/jenkins/casc_configs/secrets').with(
          user: 'jenkins',
          group: 'jenkins',
          mode: '0700',
          recursive: true
        )
      end
      it do
        is_expected.to create_osl_jenkins_config('default').with(
          cookbook: 'osl-jenkins',
          variables: {
              site_name: '10.0.0.2',
              admin_address: 'noreply@example.org',
              num_executors: 2,
          }
        )
      end
      it do
        is_expected.to create_template('/var/lib/jenkins/casc_configs/default.yml').with(
          cookbook: 'osl-jenkins',
          source: 'default.yml.erb',
          variables: {
            site_name: '10.0.0.2',
            admin_address: 'noreply@example.org',
            num_executors: 2,
          },
          owner: 'jenkins',
          group: 'jenkins',
          mode: '0400'
        )
      end
      it do
        is_expected.to create_osl_systemd_unit_drop_in('jenkins_envvars').with(
          unit_name: 'jenkins.service',
          content: <<~EOF
            [Service]
            Environment="CASC_JENKINS_CONFIG=/var/lib/jenkins/casc_configs"
            Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
            LimitNOFILE=8192
            TimeoutStartSec=590
          EOF
        )
      end
      it { is_expected.to create_osl_jenkins_config('auth') }
      it do
        is_expected.to create_template('/var/lib/jenkins/casc_configs/auth.yml').with(
          cookbook: nil,
          source: 'auth.yml.erb',
          variables: {},
          owner: 'jenkins',
          group: 'jenkins',
          mode: '0400'
        )
      end
      it { is_expected.to enable_osl_jenkins_service('default') }
      it { is_expected.to start_osl_jenkins_service('default') }
      it { is_expected.to enable_service('jenkins').with(supports: { status: true, restart: true, reload: false }) }
      it { is_expected.to start_service('jenkins').with(supports: { status: true, restart: true, reload: false }) }
    end
  end
end
