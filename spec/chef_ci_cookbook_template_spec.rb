require 'spec_helper'

describe 'osl-jenkins::chef_ci_cookbook_template' do
  ALL_PLATFORMS.each do |p|
    context "on #{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common_stubs'
      before do
        stub_command('/opt/chefdk/embedded/bin/rubocop --version | grep 0.42.0')
      end
      it do
        expect(chef_run).to include_recipe('base::chefdk')
      end
    end
  end
end
