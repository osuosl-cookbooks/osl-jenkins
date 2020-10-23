require_relative '../../spec_helper'

describe 'osl-jenkins::packer_pipeline_master' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.normal['osl-jenkins']['credentials']['jenkins'] = {
            'packer_pipeline' => {
              user: 'manatee',
              api_token: 'token_password',
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
      %w(/var/lib/jenkins/bin /var/lib/jenkins/lib).each do |d|
        it do
          expect(chef_run).to create_directory(d).with(recursive: true)
        end
      end
      it do
        expect(chef_run).to create_cookbook_file('/var/lib/jenkins/bin/packer_pipeline.rb')
          .with(
            source: 'bin/packer_pipeline.rb',
            owner: 'jenkins',
            group: 'jenkins',
            mode: '550'
          )
      end
      it do
        expect(chef_run).to create_cookbook_file('/var/lib/jenkins/lib/packer_pipeline.rb')
          .with(
            source: 'lib/packer_pipeline.rb',
            owner: 'jenkins',
            group: 'jenkins',
            mode: '440'
          )
      end
      %w(git octokit faraday-http-cache).each do |g|
        it do
          expect(chef_run).to install_chef_gem(g).with(compile_time: true)
        end
      end

      it 'creates the directory' do
        expect(chef_run).to create_directory('/var/chef/cache/packer_pipeline').with(recursive: true)
      end

      it 'creates the packer_pipeline jenkins job' do
        expect(chef_run).to create_jenkins_job('packer_pipeline').with(
          config: '/var/chef/cache/packer_pipeline/config.xml'
        )
      end

      it 'creates the github pr job config file' do
        expect(chef_run).to create_template('/var/chef/cache/packer_pipeline/config.xml')
          .with(
            source: 'packer_pipeline.config.xml.erb',
            mode: '440'
          )
      end
    end
  end
end
