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
      it do
        expect(chef_run).to add_yum_version_lock('jenkins')
          .with(
            version: '2.190.3',
            release: '1.1'
          )
      end
      it do
        expect(chef_run).to install_package('jenkins').with(version: '2.190.3-1.1', flush_cache: { before: true })
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
        expect(chef_run).to_not execute_jenkins_command('safe-restart')
      end
      it do
        expect(chef_run.jenkins_command('safe-restart')).to do_nothing
      end
      context 'set secrets in attribute' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(p) do |node|
            node.normal['osl-jenkins']['credentials']['git'] = {
              'cookbook_uploader' => {
                user: 'manatee',
                token: 'token_password',
              },
              'bumpzone' => {
                'user' => 'johndoe',
                'token' => 'password',
              },
            }
            node.normal['osl-jenkins']['credentials']['ssh'] = {
              'alfred' => {
                user: 'alfred',
                private_key: 'private rsa key',
              },
              'alfred-passphrase' => {
                user: 'alfred-passphrase',
                private_key: 'private rsa key',
                passphrase: 'password',
              },
            }
          end.converge(described_recipe)
        end
        it do
          expect(chef_run).to create_jenkins_password_credentials('manatee')
            .with(
              id: 'cookbook_uploader',
              password: 'token_password'
            )
        end
        it do
          expect(chef_run).to create_jenkins_password_credentials('johndoe')
            .with(
              id: 'bumpzone',
              password: 'password'
            )
        end
        it do
          expect(chef_run).to create_jenkins_private_key_credentials('alfred')
            .with(
              id: 'alfred',
              private_key: 'private rsa key',
              passphrase: nil
            )
        end
        it do
          expect(chef_run).to create_jenkins_private_key_credentials('alfred-passphrase')
            .with(
              id: 'alfred-passphrase',
              private_key: 'private rsa key',
              passphrase: 'password'
            )
        end
      end
      context 'set secrets databag' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(p).converge(described_recipe)
        end
        before do
          stub_data_bag_item('osl_jenkins', 'secrets')
            .and_return(
              'git' => {
                'cookbook_uploader' => {
                  'user' => 'manatee',
                  'token' => 'token_password',
                },
                'bumpzone' => {
                  'user' => 'johndoe',
                  'token' => 'password',
                },
              },
              'ssh' => {
                'alfred' => {
                  'user' => 'alfred',
                  'private_key' => 'private rsa key',
                },
                'alfred-passphrase' => {
                  'user' => 'alfred-passphrase',
                  'private_key' => 'private rsa key',
                  'passphrase' => 'password',
                },
              }
            )
        end
        it do
          expect(chef_run).to create_jenkins_password_credentials('manatee')
            .with(
              id: 'cookbook_uploader',
              password: 'token_password'
            )
        end
        it do
          expect(chef_run).to create_jenkins_password_credentials('johndoe')
            .with(
              id: 'bumpzone',
              password: 'password'
            )
        end
        it do
          expect(chef_run).to create_jenkins_private_key_credentials('alfred')
            .with(
              private_key: 'private rsa key',
              passphrase: nil
            )
        end
        it do
          expect(chef_run).to create_jenkins_private_key_credentials('alfred-passphrase')
            .with(
              private_key: 'private rsa key',
              passphrase: 'password'
            )
        end
      end
      context 'non-404 databag response' do
        cached(:chef_run) do
          ChefSpec::SoloRunner.new(p).converge(described_recipe)
        end
        before do
          stub_data_bag_item('osl_jenkins', 'secrets')
            .and_raise(Net::HTTPClientException.new(
                         'osl_jenkins databag not found',
                         Net::HTTPResponse.new('1.1', '503', '')
                       ))
        end
        it do
          expect { chef_run }.to raise_error(Net::HTTPClientException, 'osl_jenkins databag not found')
        end
      end
    end
  end
end
