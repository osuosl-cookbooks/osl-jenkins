#
# Cookbook:: osl-jenkins
# Recipe:: ibmz_ci
#
# Copyright:: 2018, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class ::Chef::Recipe
  include OSLDocker::Helper
end

node.default['osl-jenkins']['secrets_item'] = 'ibmz_ci'
secrets = credential_secrets
admin_users = secrets['admin_users']
normal_users = secrets['normal_users']
client_id = secrets['oauth']['ibmz_ci']['client_id']
client_secret = secrets['oauth']['ibmz_ci']['client_secret']
ibmz_ci = node['osl-jenkins']['ibmz_ci']
docker_cert = Chef::EncryptedDataBagItem.load(
  node['osl-docker']['data_bag'],
  "client-#{node['fqdn'].tr('.', '-')}"
)

ruby_block 'Set jenkins username/password if needed' do
  block do
    if ::File.exist?('/var/lib/jenkins/config.xml') &&
       ::File.foreach('/var/lib/jenkins/config.xml').grep(/GithubSecurityRealm/).any?
      node.run_state[:jenkins_username] = secrets['git']['ibmz_ci']['user'] # ~FC001
      node.run_state[:jenkins_password] = secrets['git']['ibmz_ci']['token'] # ~FC001
    end
  end
end

node.default['osl-jenkins']['restart_plugins'] = %w(
  credentials:2.1.13
  ssh-credentials:1.13
  ssh-slaves:1.26
  token-macro:2.4
  durable-task:1.17
  docker-java-api:3.0.14
  docker-plugin:1.1.3
  plain-credentials:1.4
  ace-editor:1.1
  jquery-detached:1.2.1
  structs:1.10
  display-url-api:2.0
  cloudbees-folder:6.0.3
  scm-api:2.2.6
  branch-api:2.0.8
  script-security:1.39
  workflow-step-api:2.14
  workflow-scm-step:2.4
  workflow-api:2.25
  workflow-support:2.18
  workflow-cps:2.39
  workflow-job:2.10
  workflow-multibranch:2.14
  junit:1.24
  matrix-project:1.10
  mailer:1.20
  jackson2-api:2.7.3
  git-client:2.5.0
  git:3.5.1
  git-server:1.7
  github-api:1.90
  github:1.27.0
  github-branch-source:2.2.3
  github-oauth:0.27
  icon-shim:2.0.3
  authentication-tokens:1.3
  embeddable-build-status:1.9
  matrix-auth:1.5
  cloud-stats:0.11
  config-file-provider:2.16.2
  resource-disposer:0.6
  openstack-cloud:2.22
)

node.default['osl-jenkins']['plugins'] = %w(
  docker-commons:1.11
  pipeline-model-extensions:1.1.3
  emailext-template:1.0
  pipeline-stage-tags-metadata:1.1.3
  workflow-cps-global-lib:2.8
  bouncycastle-api:2.16.2
  handlebars:1.1.1
  credentials-binding:1.15
  email-ext:2.57.2
  pipeline-milestone-step:1.3.1
  pipeline-rest-api:2.6
  docker-build-publish:1.3.2
  pipeline-input-step:2.8
  momentjs:1.1.1
  pipeline-build-step:2.5.1
  build-monitor-plugin:1.11+build.201701152243
  pipeline-multibranch-defaults:1.1
  pipeline-model-declarative-agent:1.1.1
  docker-workflow:1.15.1
  workflow-durable-task-step:2.18
  pipeline-model-definition:1.1.3
  workflow-basic-steps:2.4
  pipeline-model-api:1.1.3
  pipeline-stage-step:2.2
  pipeline-graph-analysis:1.3
  workflow-aggregator:2.5
  job-restrictions:0.6
  pipeline-stage-view:2.6
  command-launcher:1.2
  build-token-root:1.4
)

include_recipe 'osl-jenkins::master'

if Chef::Config[:solo] && !defined?(ChefSpec)
  Chef::Log.warn('This recipe uses search which Chef Solo does not support') if Chef::Config[:solo]
else
  docker_hosts = "\n"
  ibmz_ci_docker = search(
    :node,
    'roles:ibmz_ci_docker',
    filter_result: {
      'ipaddress' => ['ipaddress'],
      'fqdn' => ['fqdn']
    }
  )
end

unless ibmz_ci_docker.nil?
  ibmz_ci_docker.each do |host|
    docker_hosts += add_docker_host(host['fqdn'], host['ipaddress'], 'credentials_server')
  end
end

docker_images = "\n"
ibmz_ci['docker_images'].each do |image|
  docker_images +=
    add_docker_image(
      image,
      ibmz_ci['docker_public_key'],
      ibmz_ci['docker']['memory_limit'],
      ibmz_ci['docker']['memory_swap'],
      ibmz_ci['docker']['cpu_shared']
    )
end

jenkins_script 'Add Docker Cloud' do
  command <<-EOH.gsub(/^ {4}/, '')
    // Mostly from:
    // https://gist.github.com/stuart-warren/e458c8439bcddb975c96b96bec3971b6
    //
    import jenkins.model.*;
    import hudson.model.*;
    import com.cloudbees.plugins.credentials.CredentialsProvider
    import com.cloudbees.jenkins.plugins.sshcredentials.SSHUserPrivateKey
    import com.nirima.jenkins.plugins.docker.DockerCloud
    import com.nirima.jenkins.plugins.docker.DockerTemplate
    import com.nirima.jenkins.plugins.docker.DockerTemplateBase
    import io.jenkins.docker.connector.DockerComputerAttachConnector
    import io.jenkins.docker.connector.DockerComputerSSHConnector
    import org.jenkinsci.plugins.docker.commons.credentials.DockerServerCredentials
    import com.nirima.jenkins.plugins.docker.launcher.DockerComputerLauncher
    import com.nirima.jenkins.plugins.docker.launcher.DockerComputerSSHLauncher
    import org.jenkinsci.plugins.docker.commons.credentials.DockerServerEndpoint
    import com.cloudbees.plugins.credentials.*
    import com.cloudbees.plugins.credentials.common.*
    import com.cloudbees.plugins.credentials.domains.*
    import com.cloudbees.plugins.credentials.impl.*
    import hudson.plugins.sshslaves.verifiers.SshHostKeyVerificationStrategy
    import hudson.plugins.sshslaves.verifiers.NonVerifyingKeyVerificationStrategy

    def instance = Jenkins.getInstance()
    if (instance.pluginManager.activePlugins.find { it.shortName == "docker-plugin" } != null) {
      // Find docker host credentials
      id_matcher_server = CredentialsMatchers.withId('ibmz_ci_docker-server')
      available_credentials_server =
        CredentialsProvider.lookupCredentials(
        StandardUsernameCredentials.class,
        instance,
        hudson.security.ACL.SYSTEM,
        null
        )

      credentials_server =
        CredentialsMatchers.firstOrNull(
        available_credentials_server,
        id_matcher_server
        )

      if(credentials_server == null) {
        DockerServerCredentials credentials_docker_host =
          new DockerServerCredentials(
            CredentialsScope.GLOBAL,
            "ibmz_ci_docker-server",
            "Docker client certificate",
            "#{docker_cert['key'].gsub("\n",'\n')}",
            "#{docker_cert['cert'].gsub("\n",'\n')}",
            "#{docker_cert['chain'].gsub("\n",'\n')}"
            )
        CredentialsProvider.lookupStores(instance).iterator().next().addCredentials(
          Domain.global(),
          credentials_docker_host
        )
      }


      // Find ssh credentials
      id_matcher = CredentialsMatchers.withId('ibmz_ci-docker')
      available_credentials =
        CredentialsProvider.lookupCredentials(
        StandardUsernameCredentials.class,
        instance,
        hudson.security.ACL.SYSTEM,
        new SchemeRequirement("ssh")
        )

      credentials =
        CredentialsMatchers.firstOrNull(
        available_credentials,
        id_matcher
        )

      if(credentials == null) {
        println("ERROR: Unable to find ibmz_ci-docker credentials")
        return
      }

      // Setup ssh to docker nodes using our ibmz_ci-docker credentials
      SshHostKeyVerificationStrategy strategy = new NonVerifyingKeyVerificationStrategy()
      DockerComputerSSHConnector sshConnector =
        new DockerComputerSSHConnector(
          new DockerComputerSSHConnector.ManuallyConfiguredSSHKey('ibmz_ci-docker', strategy)
        )
      ArrayList<DockerTemplate> dkTemplates = new ArrayList<DockerTemplate>();
      #{docker_images}
      ArrayList<DockerCloud> dkCloud = new ArrayList<DockerCloud>();
      #{docker_hosts}
      println '--> Configuring docker cloud'
      instance.clouds.replaceBy(dkCloud)

    } else {
      println "--> no 'docker-plugin' plugin installed"
    }
  EOH
end

jenkins_script 'Add GitHub OAuth config' do
  command <<-EOH.gsub(/^ {4}/, '')
		import hudson.security.*
		import jenkins.model.*
		import org.jenkinsci.plugins.GithubAuthorizationStrategy
		import hudson.security.AuthorizationStrategy
		import hudson.security.SecurityRealm
		import org.jenkinsci.plugins.GithubSecurityRealm
		import hudson.security.ProjectMatrixAuthorizationStrategy
		import hudson.security.csrf.DefaultCrumbIssuer

		Jenkins.instance.crumbIssuer = new DefaultCrumbIssuer(true)

		// Authentication
		String githubWebUri = 'https://github.com'
		String githubApiUri = 'https://api.github.com'
		String clientID = '#{client_id}'
		String clientSecret = '#{client_secret}'
		String oauthScopes = 'read:org'
		SecurityRealm github_realm = new GithubSecurityRealm(githubWebUri, githubApiUri, clientID, clientSecret, oauthScopes)
		//check for equality, no need to modify the runtime if no settings changed
		if(!github_realm.equals(Jenkins.instance.getSecurityRealm())) {
				Jenkins.instance.setSecurityRealm(github_realm)
				Jenkins.instance.save()
		}

		// Authorization
		class BuildPermission {
			static buildNewAccessList(userOrGroup, permissions) {
				def newPermissionsMap = [:]
				permissions.each {
					newPermissionsMap.put(Permission.fromId(it), userOrGroup)
				}
				return newPermissionsMap
			}
		}

		auth_strategy = new hudson.security.ProjectMatrixAuthorizationStrategy()

		authenticatedPermissions = [ "hudson.model.Hudson.Read" ]
		authenticated = BuildPermission.buildNewAccessList("authenticated", authenticatedPermissions)
		authenticated.each { p, u -> auth_strategy.add(p, u) }

    anonPermissions = [ "hudson.model.Hudson.Read" ]
		anon = BuildPermission.buildNewAccessList("anonymous", anonPermissions)
		anon.each { p, u -> auth_strategy.add(p, u) }


		adminPermissions = [
      "com.cloudbees.plugins.credentials.CredentialsProvider.Create",
      "com.cloudbees.plugins.credentials.CredentialsProvider.Delete",
      "com.cloudbees.plugins.credentials.CredentialsProvider.ManageDomains",
      "com.cloudbees.plugins.credentials.CredentialsProvider.Update",
      "com.cloudbees.plugins.credentials.CredentialsProvider.View",
      "hudson.model.Computer.Build",
      "hudson.model.Computer.Configure",
      "hudson.model.Computer.Connect",
      "hudson.model.Computer.Create",
      "hudson.model.Computer.Delete",
      "hudson.model.Computer.Disconnect",
      "hudson.model.Computer.Provision",
      "hudson.model.Hudson.Administer",
      "hudson.model.Hudson.Read",
      "hudson.model.Item.Build",
      "hudson.model.Item.Cancel",
      "hudson.model.Item.Configure",
      "hudson.model.Item.Create",
      "hudson.model.Item.Delete",
      "hudson.model.Item.Discover",
      "hudson.model.Item.Move",
      "hudson.model.Item.Read",
      "hudson.model.Item.ViewStatus",
      "hudson.model.Item.Workspace",
      "hudson.model.Run.Delete",
      "hudson.model.Run.Replay",
      "hudson.model.Run.Update",
      "hudson.model.View.Configure",
      "hudson.model.View.Create",
      "hudson.model.View.Delete",
      "hudson.model.View.Read",
      "hudson.scm.SCM.Tag"
		]
    #{admin_users}.each { au -> user = BuildPermission.buildNewAccessList(au, adminPermissions)
      user.each { p, u -> auth_strategy.add(p, u) }
    }

		userPermissions = [
			"hudson.model.Item.Build",
			"hudson.model.Item.Cancel",
			"hudson.model.Item.Configure",
			"hudson.model.Item.Create",
			"hudson.model.Item.Delete",
			"hudson.model.Item.Discover",
			"hudson.model.Item.Read",
			"hudson.model.Item.ViewStatus",
			"hudson.model.Item.Workspace"
		]
    #{normal_users}.each { nu -> user = BuildPermission.buildNewAccessList(nu, userPermissions)
      user.each { p, u -> auth_strategy.add(p, u) }
    }


		//check for equality, no need to modify the runtime if no settings changed
		if(!auth_strategy.equals(Jenkins.instance.getAuthorizationStrategy())) {
				Jenkins.instance.setAuthorizationStrategy(auth_strategy)
				Jenkins.instance.save()
		}

	EOH
end

ruby_block 'Set jenkins username/password if needed' do
  block do
    if ::File.exist?('/var/lib/jenkins/config.xml') &&
       ::File.foreach('/var/lib/jenkins/config.xml').grep(/GithubSecurityRealm/).any?
      node.run_state[:jenkins_username] = secrets['git']['ibmz_ci']['user'] # ~FC001
      node.run_state[:jenkins_password] = secrets['git']['ibmz_ci']['token'] # ~FC001
    end
  end
end
