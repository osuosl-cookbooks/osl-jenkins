def public_address
  node.fetch('cloud', {}).fetch('public_ipv4', nil) || node['fqdn']
end
