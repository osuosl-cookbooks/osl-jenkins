require_relative '../../spec_helper'

describe 'osl-jenkins::site_pr_builder' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.normal['osl-jenkins']['credentials']['git'] = {
            'site_pr_builder' => {
              user: 'manatee',
              token: 'token_password',
            },
          }
          node.normal['osl-jenkins']['credentials']['jenkins'] = {
            'site_pr_builder' => {
              user: 'manatee',
              pass: 'password',
              trigger_token: 'trigger_token',
            },
          }
        end.converge(described_recipe)
      end

      include_context 'common_stubs'
      include_context 'data_bag_stubs'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      %w(beaver-barcamp-pelican_pr_builder osuosl-pelican_pr_builder
         wiki_pr_builder docs_pr_builder).each do |job|
        it do
          expect(chef_run).to create_directory("/var/chef/cache/#{job}").with(recursive: true)
        end

        it do
          expect(chef_run).to create_jenkins_job(job)
            .with(config: "/var/chef/cache/#{job}/config.xml")
        end

        it do
          expect(chef_run).to create_template("/var/chef/cache/#{job}/config.xml")
            .with(
              source: 'site_pr_builder_config.xml.erb',
              mode: '440'
            )
        end
      end
    end
  end
end
