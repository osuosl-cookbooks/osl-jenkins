require 'spec_helper'

describe 'osl-jenkins::chef_ci_cookbook_template' do
  [CENTOS_6_OPTS, CENTOS_7_OPTS].each do |p|
    context "on #{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(CENTOS_6_OPTS).converge(described_recipe)
      end

      it 'should set chefdk version to 0.14.25' do
        expect(chef_run.node['chef_dk']['version']).to eq('0.14.25')
      end

      it do
        expect(chef_run).to install_chef_dk('chef_dk').with(version: '0.14.25')
      end
    end
  end
end
