require_relative '../../spec_helper'

describe 'osl-jenkins::powerci' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common_stubs'
      before do
        stub_data_bag_item('osl_jenkins', 'powerci').and_return(
          admin_users: ['testadmin'],
          normal_users: ['testuser'],
          'oauth' => {
            'powerci' => {
              client_id: '123456789',
              client_secret: '0987654321',
            },
          },
          'git' => {
            'powerci' => {
              'user' => 'powerci',
              'token' => 'powerci',
            },
          },
          'ssh' => {
            'powerci-docker' => {
              'private_key' => 'powerci_private_key',
            },
          }
        )
        stub_search('node', 'roles:powerci_docker').and_return(
          [
            {
              ipaddress: '192.168.0.1',
              fqdn: 'powerci-docker1.example.org',
            },
            {
              ipaddress: '192.168.0.2',
              fqdn: 'powerci-docker2.example.org',
            },
          ]
        )
      end
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      it do
        is_expected.to create_osl_jenkins_install('powerci.osuosl.org').with(
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
      it { is_expected.to enable_osl_jenkins_service 'powerci' }
      it { is_expected.to start_osl_jenkins_service 'powerci' }
      it do
        is_expected.to create_osl_jenkins_config('powerci').with(
          sensitive: true,
          variables: {
            admin_users: %w(testadmin),
            client_id: '123456789',
            client_secret: '0987654321',
            docker_hosts: [
              {
                'fqdn' => 'powerci-docker1.example.org',
                'ipaddress' => '192.168.0.1',
              },
              {
                'fqdn' => 'powerci-docker2.example.org',
                'ipaddress' => '192.168.0.2',
              },
            ],
            docker_images: %w(
              osuosl/ubuntu-ppc64le:20.04
              osuosl/ubuntu-ppc64le:22.04
              osuosl/ubuntu-ppc64le:24.04
              osuosl/debian-ppc64le:11
              osuosl/debian-ppc64le:12
              osuosl/debian-ppc64le:buster
              osuosl/debian-ppc64le:unstable
              osuosl/debian-ppc64le:sid
            ),
            docker_public_key: '',
            normal_users: %w(testuser),
          }
        )
      end
      it do
        expect(chef_run.osl_jenkins_config('powerci')).to \
          notify('osl_jenkins_service[powerci]').to(:restart).delayed
      end
    end
  end
end
