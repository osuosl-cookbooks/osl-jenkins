require 'spec_helper'

describe 'osl-jenkins::chef_ci_cookbook_template' do
  ALL_PLATFORMS.each do |p|
    context "on #{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common_stubs'
      it do
        expect(chef_run).to include_recipe('base::cinc_workstation')
      end
    end
  end
end
