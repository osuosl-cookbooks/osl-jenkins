require_relative '../../spec_helper'

describe 'osl-jenkins::chef_backup' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it { is_expected.to install_chef_gem('knife-backup').with(version: '0.0.10') }

      it do
        is_expected.to create_directory('/var/chef-backup-for-rdiff').with(
          owner: 'jenkins',
          group: 'jenkins'
        )
      end
    end
  end
end
