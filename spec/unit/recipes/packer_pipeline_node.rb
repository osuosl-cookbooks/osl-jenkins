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

      include_context 'common_stubs'
      include_context 'data_bag_stubs'

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
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
        expect(chef_run).to install_gem_package('openstack_taster').with(
          options: '--no-user-install'
        )
      end
    end
  end
end
