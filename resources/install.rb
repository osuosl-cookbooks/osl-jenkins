resource_name :osl_jenkins_install
provides :osl_jenkins_install
unified_mode true
default_action :create

property :admin_address, String, required: true
property :cli_version, String, default: '2.12.15'
property :num_executors, Integer, default: 2
property :plugins, Array
property :site_name, String, name_property: true

action :create do
  package "java-#{osl_jenkins_java_version}-openjdk-headless"

  yum_repository 'jenkins' do
    baseurl 'https://pkg.jenkins.io/redhat-stable'
    description 'Jenkins-stable'
    gpgkey 'https://pkg.jenkins.io/rpm-stable/repodata/repomd.xml.key'
    gpgcheck true
  end

  package %w(
    dejavu-sans-fonts
    fontconfig
    jenkins
  )

  certificate_manage 'wildcard' do
    cert_file 'wildcard.pem'
    key_file 'wildcard.key'
    chain_file 'wildcard-bundle.crt'
    combined_file true
    notifies :restart, 'haproxy_service[haproxy]'
  end

  include_recipe 'osl-git'

  osl_firewall_port 'http'
  osl_firewall_port 'haproxy'

  include_recipe 'osl-haproxy::install'
  include_recipe 'osl-haproxy::config'

  haproxy_frontend 'http' do
    default_backend 'jenkins'
    maxconn 2000
    extra_options(
      'redirect' => 'scheme https if !{ ssl_fc }'
    )
    notifies :restart, 'haproxy_service[haproxy]'
  end

  haproxy_frontend 'https' do
    default_backend 'jenkins'
    maxconn 2000
    bind '0.0.0.0:443 ssl crt /etc/pki/tls/certs/wildcard.pem'
    notifies :restart, 'haproxy_service[haproxy]'
  end

  haproxy_backend 'jenkins' do
    server [ 'jenkins 127.0.0.1:8080 check' ]
    option %w(forwardfor)
    extra_options(
      'http-request' => [
        'set-header X-Forwarded-Port %[dst_port]',
        'add-header X-Forwarded-Proto https if { ssl_fc }',
        'set-header X-Forwarded-Host %[req.hdr(Host)]',
      ]
    )
    notifies :restart, 'haproxy_service[haproxy]'
  end

  cli_url = 'https://github.com/jenkinsci/plugin-installation-manager-tool/releases/download'

  remote_file '/opt/jenkins-plugin-manager.jar' do
    source "#{cli_url}/#{new_resource.cli_version}/jenkins-plugin-manager-#{new_resource.cli_version}.jar"
  end

  cookbook_file '/usr/local/bin/jenkins-plugin-cli' do
    cookbook 'osl-jenkins'
    mode '0755'
  end

  [new_resource.plugins, osl_jenkins_default_plugins].flatten!.uniq.each do |plugin|
    osl_jenkins_plugin plugin if plugin
  end

  cookbook_file '/var/lib/jenkins/.gitconfig' do
    cookbook 'osl-jenkins'
    source 'gitconfig'
    owner 'jenkins'
    group 'jenkins'
  end

  [
    osl_jenkins_bin_path,
    osl_jenkins_lib_path,
  ].each do |d|
    directory d do
      owner 'jenkins'
      group 'jenkins'
    end
  end

  directory '/var/lib/jenkins/casc_configs/groovy' do
    user 'jenkins'
    group 'jenkins'
    mode '0700'
    recursive true
  end

  directory '/var/lib/jenkins/casc_configs/secrets' do
    user 'jenkins'
    group 'jenkins'
    mode '0700'
    recursive true
  end

  osl_jenkins_config 'default' do
    cookbook 'osl-jenkins'
    variables(
      site_name: new_resource.site_name,
      admin_address: new_resource.admin_address,
      num_executors: new_resource.num_executors
    )
  end

  osl_systemd_unit_drop_in 'jenkins_envvars' do
    unit_name 'jenkins.service'
    content <<~EOF
      [Service]
      Environment="CASC_JENKINS_CONFIG=/var/lib/jenkins/casc_configs"
      Environment="JAVA_OPTS=-Djava.awt.headless=true -Djenkins.install.runSetupWizard=false"
      LimitNOFILE=8192
      TimeoutStartSec=590
    EOF
  end
end
