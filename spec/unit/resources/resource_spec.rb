require_relative '../../spec_helper'

describe 'jenkins_test::resources' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.dup.merge(step_into: %w(
          osl_jenkins_client_cert_credentials
          osl_jenkins_job
          osl_jenkins_password_credentials
          osl_jenkins_plugin
          osl_jenkins_private_key_credentials
          osl_jenkins_secret
        ))).converge(described_recipe)
      end
      include_context 'common_stubs'

      casc_path = '/var/lib/jenkins/casc_configs'

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      it do
        is_expected.to create_osl_jenkins_private_key_credentials('default').with(
          username: 'username',
          private_key: 'private_key'
        )
      end
      it do
        is_expected.to create_osl_jenkins_secret('private_key_credentials_private_key_default').with(
          secret: 'private_key'
        )
      end
      it do
        is_expected.to create_file("#{casc_path}/secrets/private_key_credentials_private_key_default").with(
          content: 'private_key',
          sensitive: true,
          owner: 'jenkins',
          group: 'jenkins',
          mode: '0400'
        )
      end
      it do
        is_expected.to create_osl_jenkins_config('private_key_credentials_default').with(
          cookbook: 'osl-jenkins',
          source: 'private_key_credentials.yml.erb',
          variables: {
            name: 'default',
            scope: 'GLOBAL',
            username: 'username',
          },
          sensitive: true
        )
      end
      it do
        is_expected.to create_osl_jenkins_client_cert_credentials('default').with(
          cert: 'cert',
          key: 'key',
          chain: 'chain'
        )
      end
      it do
        is_expected.to create_osl_jenkins_secret('client_cert_credentials_cert_default').with(secret: 'cert')
      end
      it do
        is_expected.to create_osl_jenkins_secret('client_cert_credentials_key_default').with(secret: 'key')
      end
      it do
        is_expected.to create_osl_jenkins_secret('client_cert_credentials_chain_default').with(secret: 'chain')
      end
      it do
        is_expected.to create_osl_jenkins_config('client_cert_credentials_default').with(
          cookbook: 'osl-jenkins',
          source: 'client_cert_credentials.yml.erb',
          variables: {
            description: 'default',
            name: 'default',
            scope: 'GLOBAL',
          },
          sensitive: true
        )
      end
      it do
        is_expected.to create_osl_jenkins_password_credentials('default').with(
          password: 'password'
        )
      end
      it do
        is_expected.to create_osl_jenkins_secret('password_credentials_username_default').with(secret: 'default')
      end
      it do
        is_expected.to create_osl_jenkins_secret('password_credentials_password_default').with(secret: 'password')
      end
      it do
        is_expected.to create_osl_jenkins_config('password_credentials_default').with(
          cookbook: 'osl-jenkins',
          source: 'password_credentials.yml.erb',
          variables: {
            name: 'default',
            scope: 'GLOBAL',
          },
          sensitive: true
        )
      end
      it { is_expected.to create_osl_jenkins_job 'inline' }
      it do
        is_expected.to create_template('/var/lib/jenkins/casc_configs/job_inline.yml').with(
          cookbook: 'osl-jenkins',
          source: 'job.yml.erb',
          variables: {
            file: nil,
            name: 'inline',
            script: 'script',
            template: nil,
          },
          sensitive: false,
          owner: 'jenkins',
          group: 'jenkins',
          mode: '0400'
        )
      end
      it { is_expected.to create_osl_jenkins_job('template').with(template: true, variables: { default: 'default' }) }
      it do
        is_expected.to create_template('/var/lib/jenkins/casc_configs/groovy/job_template.groovy').with(
          cookbook: nil,
          source: 'job_template.groovy.erb',
          variables: {
            default: 'default',
          },
          sensitive: false,
          owner: 'jenkins',
          group: 'jenkins',
          mode: '0400'
        )
      end
      it { is_expected.to create_osl_jenkins_job('file').with(file: true) }
      it do
        is_expected.to create_cookbook_file('/var/lib/jenkins/casc_configs/groovy/job_file.groovy').with(
          cookbook: nil,
          source: 'job_file.groovy',
          sensitive: false,
          owner: 'jenkins',
          group: 'jenkins',
          mode: '0400'
        )
      end
      it { is_expected.to install_osl_jenkins_plugin 'github' }
      it do
        is_expected.to create_directory('/var/lib/jenkins').with(
          owner: 'jenkins',
          group: 'jenkins',
          recursive: true
        )
      end
      it do
        is_expected.to create_template('/var/lib/jenkins/plugins.txt').with(
          cookbook: 'osl-jenkins',
          source: 'plugins.txt.erb',
          owner: 'jenkins',
          group: 'jenkins'
        )
      end
      it do
        expect(chef_run.template('/var/lib/jenkins/plugins.txt')).to \
          notify('execute[jenkins-plugin-cli]').to(:run).immediately
      end
      it do
        is_expected.to nothing_execute('jenkins-plugin-cli').with(
          command: '/usr/local/bin/jenkins-plugin-cli --plugin-file /var/lib/jenkins/plugins.txt',
          user: 'jenkins',
          group: 'jenkins'
        )
      end
    end
  end
end
