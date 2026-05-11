require_relative '../../spec_helper'

describe 'libraries/github.rb' do
  let(:library_path) { File.expand_path('../../../libraries/github.rb', __dir__) }

  describe 'load-time middleware configuration' do
    # Regression test: when chefspec/berkshelf transitively loads Faraday::HttpCache before
    # the cookbook's chef_gem 'octokit' has been required, the eager middleware block at the
    # top of github.rb used to raise `NameError: uninitialized constant Octokit`, which
    # aborted loading of the rest of the library (helpers.rb, resource.rb, template.rb) and
    # cascaded into `osl_jenkins_java_version` / `OslJenkins` errors in any cookbook that
    # depends on osl-jenkins. The fix guards the block on both constants being defined.
    it 'does not raise when Octokit is not loaded' do
      hide_const('Octokit')
      expect { load library_path }.not_to raise_error
    end

    it 'does not raise when neither Octokit nor Faraday::HttpCache is loaded' do
      hide_const('Octokit')
      hide_const('Faraday::HttpCache') if defined?(Faraday::HttpCache)
      expect { load library_path }.not_to raise_error
    end
  end
end
