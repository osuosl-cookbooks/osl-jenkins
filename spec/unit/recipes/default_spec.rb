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
        expect(chef_run).to create_users_manage('alfred').with(group_id: 10000)
      end
      it do
        expect(chef_run.users_manage('alfred')).to notify('ohai[jenkins_reload_passwd]').to(:reload).immediately
      end
      it do
        expect(chef_run.ohai('jenkins_reload_passwd')).to do_nothing
      end
    end
  end
end
