require 'spec_helper'

describe 'osl-jenkins::chef_ci_cookbook_template' do
  [CENTOS_6_OPTS, CENTOS_7_OPTS].each do |p|
    context "on #{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(CENTOS_6_OPTS).converge(described_recipe)
      end

      it do
        expect(chef_run).to include_recipe('base::chefdk')
      end
    end
  end
end
