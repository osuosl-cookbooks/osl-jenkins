require 'spec_helper'

describe 'osl-jenkins::packer_pipeline_node' do
  [CENTOS_7_OPTS].each do |p|
    context "#{p[:platform]} #{p[:version]} on ppc64le platform" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.automatic['kernel']['machine'] = 'ppc64le'
        end.converge(described_recipe)
      end

      include_context 'common_stubs'
      include_context 'data_bag_stubs'

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it do
        expect(chef_run).to create_link('/usr/local/bin/packer')
      end

      it do
        expect(chef_run).to create_remote_file('/usr/local/bin/packer-v1.0.3-dev').with(
          source: 'http://ftp.osuosl.org/pub/osl/openpower/packer/packer-v1.0.3-dev'
        )
      end
    end

    context "#{p[:platform]} #{p[:version]} on x86_64 platform" do
      cached(:chef_run) do
        runner = ChefSpec::SoloRunner.new(p)
        runner.converge(described_recipe)
      end

      before do
        # stub absence of openstack commandline tool
        allow(File).to receive(:executable?).and_return(false)
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
        expect(chef_run).to create_file('/home/alfred/openstack_credentials.json').with(
          user: 'alfred',
          group: 'alfred',
          mode: 0600
        )
      end

      it do
        expect(chef_run).to install_chef_gem('openstack_taster').with(
          options: '--no-user-install'
        )
      end

      it do
        expect(chef_run).to install_python_package('python-openstackclient')
      end

      it do
        expect(chef_run).to install_package('chefdk')
      end
    end

    context 'when openstack client is already installed' do
      cached(:chef_run) do
        runner = ChefSpec::SoloRunner.new(p)
        runner.converge(described_recipe)
      end

      include_context 'common_stubs'
      include_context 'data_bag_stubs'

      it do
        # stub presence of openstack commandline tool
        allow(File).to receive(:executable?).and_return(true)
        expect(chef_run).to_not install_python_package('python-openstackclient')
      end
    end
  end
end
