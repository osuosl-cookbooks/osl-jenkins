require_relative '../../spec_helper'

describe 'osl-jenkins::bumpzone' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      it do
        expect(chef_run).to create_template(::File.join(Chef::Config[:file_cache_path], 'bumpzone', 'config.xml'))
          .with(variables: { github_url: 'foo', github_clone_url: 'bar' })
      end
    end
  end
end
