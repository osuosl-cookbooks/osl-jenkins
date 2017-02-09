require_relative '../../spec_helper'

describe 'osl-jenkins::bumpzone' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.set['osl-jenkins']['credentials']['git'] = {
            'bumpzone' => {
              user: 'manatee',
              token: 'token_password',
              url: 'github.com'
            }
          }
          node.set['osl-jenkins']['credentials']['jenkins'] = {
            'bumpzone' => {
              user: 'manatee',
              pass: 'password',
              trigger_token: 'trigger_token'
            }
          }
        end.converge(described_recipe)
      end
      include_context 'common_stubs'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      %w(/var/lib/jenkins/bin /var/lib/jenkins/lib).each do |d|
        it do
          expect(chef_run).to create_directory(d).with(recursive: true)
        end
      end
      it do
        expect(chef_run).to create_cookbook_file('/var/lib/jenkins/bin/bumpzone.rb')
          .with(
            source: 'bin/bumpzone.rb',
            owner: 'jenkins',
            group: 'jenkins',
            mode: 0550
          )
      end
      it do
        expect(chef_run).to create_cookbook_file('/var/lib/jenkins/lib/bumpzone.rb')
          .with(
            source: 'lib/bumpzone.rb',
            owner: 'jenkins',
            group: 'jenkins',
            mode: 0440
          )
      end
      it do
        expect(chef_run).to create_directory('/var/chef/cache/bumpzone').with(recursive: true)
      end
      it do
        expect(chef_run).to create_template('/var/chef/cache/bumpzone/config.xml')
          .with(
            source: 'bumpzone.config.xml.erb',
            mode: 0440,
            variables: {
              github_token: 'token_password',
              github_url: 'https://github.com/osuosl/zonefiles.git',
              trigger_token: 'trigger_token'
            }
          )
      end
      it do
        expect(chef_run).to create_jenkins_job('bumpzone').with(config: '/var/chef/cache/bumpzone/config.xml')
      end
    end
  end
end
