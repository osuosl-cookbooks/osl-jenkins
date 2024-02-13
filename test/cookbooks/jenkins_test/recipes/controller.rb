osl_jenkins_install node['ipaddress'] do
  admin_address 'noreply@example.org'
  notifies :restart, 'osl_jenkins_service[default]', :delayed
end

osl_jenkins_config 'auth' do
  notifies :restart, 'osl_jenkins_service[default]', :delayed
end

osl_jenkins_service 'default' do
  action [:enable, :start]
end
