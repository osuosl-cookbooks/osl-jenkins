require_relative '../../spec_helper'

describe 'osl-jenkins::bumpzone' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p) do |node|
          node.normal['osl-jenkins']['credentials']['git'] = {
            'bumpzone' => {
              user: 'manatee',
              token: 'token_password',
            },
          }
          node.normal['osl-jenkins']['credentials']['jenkins'] = {
            'bumpzone' => {
              user: 'manatee',
              api_token: 'api_token',
              trigger_token: 'trigger_token',
            },
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
      %w(bumpzone.rb checkzone.rb).each do |f|
        it do
          expect(chef_run).to create_cookbook_file("/var/lib/jenkins/bin/#{f}")
            .with(
              source: "bin/#{f}",
              owner: 'jenkins',
              group: 'jenkins',
              mode: 0550
            )
        end
        it do
          expect(chef_run).to create_cookbook_file("/var/lib/jenkins/lib/#{f}")
            .with(
              source: "lib/#{f}",
              owner: 'jenkins',
              group: 'jenkins',
              mode: 0440
            )
        end
      end
      it do
        expect(chef_run).to install_package('bind')
      end
      %w(bumpzone checkzone update-zonefiles).each do |j|
        it do
          expect(chef_run).to create_directory("/var/chef/cache/#{j}").with(recursive: true)
        end
        it do
          expect(chef_run).to create_jenkins_job(j).with(config: "/var/chef/cache/#{j}/config.xml")
        end
      end
      it do
        expect(chef_run).to create_template('/var/chef/cache/bumpzone/config.xml')
          .with(
            source: 'bumpzone.config.xml.erb',
            mode: 0440,
            variables: {
              github_url: 'https://github.com/osuosl/zonefiles.git',
              trigger_token: 'trigger_token',
            }
          )
      end
      it do
        expect(chef_run).to create_template('/var/chef/cache/checkzone/config.xml')
          .with(
            source: 'checkzone.config.xml.erb',
            mode: 0440,
            variables: {
              github_url: 'https://github.com/osuosl/zonefiles.git',
              trigger_token: 'trigger_token',
            }
          )
      end
      it do
        expect(chef_run).to create_template('/var/chef/cache/update-zonefiles/config.xml')
          .with(
            source: 'update-zonefiles.config.xml.erb',
            mode: 0440,
            variables: {
              github_url: 'https://github.com/osuosl/zonefiles.git',
              dns_master: 'dns_master',
            }
          )
      end
    end
  end
end
