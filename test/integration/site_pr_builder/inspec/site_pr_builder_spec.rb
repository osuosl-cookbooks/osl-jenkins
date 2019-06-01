sites = %w(beaver-barcamp-pelican_pr_builder osuosl-pelican_pr_builder
           wiki_pr_builder docs_pr_builder)

sites.each do |job|
  # describe command("curl -k https://127.0.0.1/job/#{job}/ -o /dev/null -v 2>&1") do
  #   its('stdout') { should match(/X-Jenkins-Session:/) }
  #   its('exit_status') { should eq 0 }
  # end

  describe http('https://127.0.0.1/job/#{job}/', enable_remote_worker: true, ssl_verify: false) do
    its('body') { should match(/X-Jenkins-Session:/) }
  end
end
