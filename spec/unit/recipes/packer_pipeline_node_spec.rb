require_relative '../../spec_helper.rb'

describe 'osl-jenkins::packer_pipeline_node' do
  [CENTOS_7_OPTS].each do |p|
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

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it do
        expect(chef_run).to create_file('/home/alfred/.ssh/packer_alfred_id').with(
          user: 'alfred',
          group: 'alfred',
          mode: 0600,
          content: 'private key for openstack_taster goes here'
        )
      end

      it do
        expect(chef_run).to create_file('/home/alfred/.ssh/packer_alfred_id.pub').with(
          user: 'alfred',
          group: 'alfred',
          mode: 0600,
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
          mode: 0600,
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
          mode: 0600
        )
      end

      it do
        expect(chef_run).to upgrade_chef_gem('openstack_taster').with(
          options: '--no-user-install',
          clear_sources: true
        )
      end
    end
  end
end
