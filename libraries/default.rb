def public_address
  node['osl-jenkins']['cookbook_uploader']['jenkins_server']
end

def credential_secrets
  data_bag_item(
    node['osl-jenkins']['secrets_databag'],
    node['osl-jenkins']['secrets_item']
  )
rescue Net::HTTPServerException => e
  databag = "#{node['osl-jenkins']['secrets_databag']}:#{node['osl-jenkins']['secrets_item']}"
  if e.response.code == '404'
    Chef::Log.warn("Could not find databag '#{databag}'; falling back to default attributes.")
    node['osl-jenkins']['credentials']
  else
    Chef::Log.fatal("Unable to load databag '#{databag}'; exiting. Please fix the databag and try again.")
    raise
  end
end
