# describe command('curl -k https://127.0.0.1/credentials/store/system/domain/_/') do
#   its(:stdout) { should match(/alfred \(Credentials for alfred - created by Chef\)/) }
# end

describe http('https://127.0.0.1/credentials/store/system/domain/_/', enable_remote_worker: true, ssl_verify: false) do
   its('body') { should match(/alfred \(Credentials for alfred - created by Chef\)/) }
end
