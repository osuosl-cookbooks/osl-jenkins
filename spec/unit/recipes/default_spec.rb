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

      case p
      when CENTOS_7
        it { expect(chef_run).to install_package 'java-11-openjdk-headless' }
      when ALMA_8
        it { expect(chef_run).to install_package 'java-21-openjdk-headless' }
      end

      it do
        expect(chef_run).to create_users_manage('alfred').with(
          group_id: 10000,
          users: [{
            'id' => 'alfred',
            'ssh_keys' => [
              'test_ssh_key',
            ],
          }]
        )
      end
    end
  end
end
