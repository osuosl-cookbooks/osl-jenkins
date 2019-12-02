sites = %w(
  beaver-barcamp-pelican_pr_builder
  osuosl-pelican_pr_builder
  wiki_pr_builder docs_pr_builder)

sites.each do |job|
  describe http("https://127.0.0.1/job/#{job}/", ssl_verify: false) do
    its('status') { should eq 200 }
    its('headers.X-Jenkins') { should_not eq nil }
  end
end
