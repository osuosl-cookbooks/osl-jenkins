describe command('curl -k https://127.0.0.1/credentials/store/system/domain/_/ \
                 | iconv -f US-ASCII -t UTF-8') do
  its('stdout') { should match(/alfred \(Credentials for alfred - created by Chef\)/) }
end
