require_relative '../../spec_helper'

describe 'osl-jenkins::master' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p).converge(described_recipe)
      end
      include_context 'common_stubs'
      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end
      case p
      when CENTOS_6_OPTS
        it do
          expect(chef_run).to create_link('/usr/bin/git').with(to: '/usr/local/bin/git')
        end
      end
      it do
        expect(chef_run).to create_directory('/var/lib/jenkins')
          .with(recursive: true)
      end
      it do
        expect(chef_run).to create_template('/var/lib/jenkins/.git-credentials')
          .with(
            source: 'git-credentials.erb',
            mode: '0400',
            owner: 'jenkins',
            group: 'jenkins',
            variables: { credentials: [] }
          )
      end
      it do
        expect(chef_run).to create_cookbook_file('/var/lib/jenkins/.gitconfig')
          .with(
            source: 'gitconfig',
            owner: 'jenkins',
            group: 'jenkins'
          )
      end
      it do
        expect(chef_run).to create_template('/var/lib/jenkins/.git-credentials')
      end
      context 'set secrets databag' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(p).converge(described_recipe)
        end
        before do
          allow(Chef::EncryptedDataBagItem).to receive(:load)
            .with('osl_jenkins', 'secrets')
            .and_return(
              'git' => {
                'cookbook_uploader' => {
                  'user' => 'manatee',
                  'token' => 'token_password',
                  'url' => 'github.com'
                },
                'bumpzone' => {
                  'user' => 'johndoe',
                  'token' => 'password',
                  'url' => 'github.com/osuosl'
                }
              }
            )
        end
        [
          %r{^https://manatee:token_password@github.com$},
          %r{^https://johndoe:password@github.com/osuosl$}
        ].each do |line|
          it do
            expect(chef_run).to render_file('/var/lib/jenkins/.git-credentials').with_content(line)
          end
        end
      end
      context 'non-404 databag response' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(p).converge(described_recipe)
        end
        before do
          allow(Chef::EncryptedDataBagItem).to receive(:load)
            .with('osl_jenkins', 'secrets')
            .and_raise(Net::HTTPServerException.new(
                         'osl_jenkins databag not found',
                         Net::HTTPResponse.new('1.1', '503', '')
            ))
        end
        it do
          expect { chef_run }.to raise_error(Net::HTTPServerException, 'osl_jenkins databag not found')
        end
      end
    end
  end
end
