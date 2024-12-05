require_relative '../../spec_helper'

describe 'osl-jenkins::ibmz_ci' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common_stubs'
      before do
        stub_data_bag_item('osl_jenkins', 'ibmz_ci').and_return(
          admin_users: ['testadmin'],
          normal_users: ['testuser'],
          'oauth' => {
            'ibmz_ci' => {
              client_id: '123456789',
              client_secret: '0987654321',
            },
          },
          'git' => {
            'ibmz_ci' => {
              'user' => 'ibmz_ci',
              'token' => 'ibmz_ci',
            },
          },
          'ssh' => {
            'ibmz_ci-docker' => {
              'private_key' => 'ibmz_ci_private_key',
            },
          }
        )
        stub_data_bag_item('docker', 'client-fauxhai-local').and_return(
          key: 'key',
          cert: 'cert',
          chain: 'chain'
        )
        stub_search('node', 'roles:ibmz_ci_docker').and_return(
          [
            {
              ipaddress: '192.168.0.1',
              fqdn: 's390x-docker1.example.org',
            },
            {
              ipaddress: '192.168.0.2',
              fqdn: 's390x-docker2.example.org',
            },
          ]
        )
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      it do
        is_expected.to create_osl_jenkins_install('ibmz-ci.osuosl.org').with(
          admin_address: 'nobody@osuosl.org',
          num_executors: 0,
          plugins: %w(
            ansicolor
            basic-branch-build-strategies
            build-monitor-plugin
            build-timeout
            cloud-stats
            config-file-provider
            disable-github-multibranch-status
            docker-java-api
            docker-plugin
            email-ext
            emailext-template
            embeddable-build-status
            extended-read-permission
            github-oauth
            job-restrictions
            jquery
            label-linked-jobs
            nodelabelparameter
            pipeline-githubnotify-step
            pipeline-multibranch-defaults
            resource-disposer
          )
        )
      end
      it { is_expected.to enable_osl_jenkins_service 'ibmz-ci' }
      it { is_expected.to start_osl_jenkins_service 'ibmz-ci' }
      it do
        is_expected.to create_osl_jenkins_config('ibmz-ci').with(
          sensitive: true,
          variables: {
            admin_users: %w(testadmin),
            client_id: '123456789',
            client_secret: '0987654321',
            docker_hosts: [
              {
                'fqdn' => 's390x-docker1.example.org',
                'ipaddress' => '192.168.0.1',
              },
              {
                'fqdn' => 's390x-docker2.example.org',
                'ipaddress' => '192.168.0.2',
              },
            ],
            docker_images: %w(
              osuosl/ubuntu-s390x:16.04
              osuosl/ubuntu-s390x:18.04
              osuosl/debian-s390x:9
              osuosl/debian-s390x:buster
              osuosl/debian-s390x:unstable
              osuosl/fedora-s390x:28
              osuosl/fedora-s390x:29
            ),
            docker_public_key: '',
            normal_users: %w(testuser),
          }
        )
      end
      it do
        expect(chef_run.osl_jenkins_config('ibmz-ci')).to \
          notify('osl_jenkins_service[ibmz-ci]').to(:restart).delayed
      end
    end
  end
end
