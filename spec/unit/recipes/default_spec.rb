require_relative '../../spec_helper'

describe 'osl-jenkins::default' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common_stubs'
      include_context 'data_bag_stubs'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      it do
        expect(chef_run).to create_group('alfred')
      end
      it do
        expect(chef_run).to create_user('alfred').with(
          manage_home: true,
          gid: 'alfred',
          system: true,
          shell: '/bin/bash',
          home: '/home/alfred'
        )
      end
      it do
        expect(chef_run).to reload_ohai('reload_passwd').with(
          plugin: 'etc'
        )
      end
    end
  end
end
