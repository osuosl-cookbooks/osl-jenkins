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
      it do
        expect(chef_run).to install_package('jenkins').with(version: '2.46.3-1.1')
      end
      case p
      when CENTOS_6_OPTS
        it do
          expect(chef_run).to create_link('/usr/bin/git').with(to: '/usr/local/bin/git')
        end
      end
    end
  end
end
