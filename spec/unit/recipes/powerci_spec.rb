require_relative '../../spec_helper'

describe 'osl-jenkins::powerci' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common_stubs'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      %w(
        build-monitor-plugin:1.11+build.201701152243
        docker-commons:1.6
        docker-plugin:0.16.2
        docker-build-publish:1.3.2
        embeddable-build-status:1.9
        git-client:2.4.5
        github-api:1.85
        github-oauth:0.27
        job-restrictions:0.6
        matrix-project:1.10
        yet-another-docker-plugin:0.1.0-rc37
      ).each do |plugins_version|
        plugin, version = plugins_version.split(':')
        it do
          expect(chef_run).to install_jenkins_plugin(plugin).with(
            version: version,
            install_deps: false
          )
        end
        it do
          expect(chef_run.jenkins_plugin(plugin)).to notify('jenkins_command[safe-restart]')
        end
      end
    end
  end
end
