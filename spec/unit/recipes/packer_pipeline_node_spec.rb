require_relative '../../spec_helper'

describe 'osl-jenkins::packer_pipeline_node' do
  [CENTOS_7].each do |p|
    context "special things for #{p[:platform]} #{p[:version]} on ppc64le arch" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.automatic['kernel']['machine'] = 'ppc64le'
          node.automatic['filesystem2']['by_mountpoint']
          node.normal['ibm_power']['cpu']['cpu_model'] = 'power8'
        end.converge(described_recipe)
      end

      include_context 'common_stubs'
      include_context 'data_bag_stubs'
      before do
        stub_command('/opt/os-client/bin/pip -V | grep -q "^pip 9.0.1"').and_return(true)
        stub_command('/opt/os-client/bin/easy_install --version | grep -q "^setuptools 28.8.0"').and_return(true)
        stub_command('/opt/os-client/bin/pip freeze | grep -q dogpile && /opt/os-client/bin/pip freeze | grep -q python-openstackclient==3.14.3').and_return(true)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it do
        expect(chef_run).to install_build_essential('osl-jenkins-packer-pipeline-node').with(compile_time: true)
      end

      it do
        expect(chef_run).to create_file('/home/alfred/.ssh/packer_alfred_id').with(
          user: 'alfred',
          group: 'alfred',
          mode: '600',
          content: 'private key for openstack_taster goes here'
        )
      end

      it do
        expect(chef_run).to create_file('/home/alfred/.ssh/packer_alfred_id.pub').with(
          user: 'alfred',
          group: 'alfred',
          mode: '600',
          content: 'public key for openstack_taster goes here'
        )
      end

      it do
        expect(chef_run).to create_directory('/home/alfred/workspace').with(
          user: 'alfred',
          group: 'alfred'
        )
      end

      it do
        expect(chef_run).to create_cookbook_file('/home/alfred/.gitconfig').with(
          user: 'alfred',
          group: 'alfred'
        )
      end

      it do
        expect(chef_run).to create_template('/home/alfred/.git-credentials').with(
          user: 'alfred',
          group: 'alfred',
          mode: '600',
          variables: {
            username: 'osuosl-manatee',
            password: 'FAKE_TOKEN',
          }
        )
      end

      it do
        expect(chef_run).to create_file('/home/alfred/openstack_credentials.json').with(
          user: 'alfred',
          group: 'alfred',
          mode: '600'
        )
      end

      # it do
      #   expect(chef_run).to upgrade_chef_gem('openstack_taster').with(
      #     options: '--no-user-install',
      #     version: '>= 2.0',
      #     clear_sources: true
      #   )
      # end
    end
  end
end
