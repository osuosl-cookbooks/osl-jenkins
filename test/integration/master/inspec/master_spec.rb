describe command('curl -k https://127.0.0.1/credentials/store/system/domain/_/') do
  its('stdout') { should match(/alfred \(Credentials for alfred - created by Chef\)/) }
end
