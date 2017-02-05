require_relative '../../spec_helper'

describe 'osl-jenkins::jenkins1' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.set['osl-jenkins']['cookbook_uploader'] = {
            'override_repos' => %w(test-cookbook),
            'github_insecure_hook' => true,
            'do_not_upload_cookbooks' => true
          }
        end.converge(described_recipe)
      end
      include_context 'cookbook_uploader'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
    end
  end
end
