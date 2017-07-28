#
# Cookbook Name:: osl-jenkins
# Recipe:: powerci
#
# Copyright 2017, Oregon State University
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
#

items = data_bag_item('osl_jenkins', 'powerci')
admin_users = items['admin_users']
normal_users = items['normal_users']
client_id = items['client_id']
client_secret = items['client_secret']

ruby_block 'Set jenkins username/password if needed' do
  block do
    if ::File.exist?('/var/lib/jenkins/config.xml') &&
       ::File.foreach('/var/lib/jenkins/config.xml').grep(/GithubSecurityRealm/).any?
      node.run_state[:jenkins_username] = 'osuosl-manatee' # ~FC001
      node.run_state[:jenkins_password] = items['cli_password'] # ~FC001
    end
  end
end

node.default['osl-jenkins']['restart_plugins'] = %w(
  credentials:2.1.13
  ssh-credentials:1.13
  ssh-slaves:1.17
  token-macro:2.1
  durable-task:1.13
  docker-plugin:0.16.2
  plain-credentials:1.4
  ace-editor:1.1
  jquery-detached:1.2.1
  structs:1.6
  display-url-api:2.0
  branch-api:2.0.8
  cloudbees-folder:6.0.3
  scm-api:2.1.1
  script-security:1.27
  workflow-step-api:2.9
  workflow-support:2.14
  workflow-scm-step:2.4
  workflow-api:2.13
  workflow-cps:2.30
  workflow-job:2.10
  workflow-multibranch:2.14
  junit:1.20
  matrix-project:1.10
  mailer:1.20
  git-client:2.4.5
  git:3.3.0
  git-server:1.7
  github-api:1.85
  github:1.27.0
  github-branch-source:2.0.5
  github-oauth:0.27
  icon-shim:2.0.3
  matrix-auth:1.5
  authentication-tokens:1.3

)

node.default['osl-jenkins']['plugins'] = %w(
  docker-commons:1.6
  resource-disposer:0.6
  pipeline-model-extensions:1.1.3
  emailext-template:1.0
  pipeline-stage-tags-metadata:1.1.3
  workflow-cps-global-lib:2.8
  openstack-cloud:2.22
  bouncycastle-api:2.16.1
  config-file-provider:2.15.7
  handlebars:1.1.1
  credentials-binding:1.11
  email-ext:2.57.2
  pipeline-milestone-step:1.3.1
  pipeline-rest-api:2.6
  docker-build-publish:1.3.2
  pipeline-input-step:2.7
  momentjs:1.1.1
  pipeline-build-step:2.5
  yet-another-docker-plugin:0.1.0-rc37
  embeddable-build-status:1.9
  build-monitor-plugin:1.11+build.201701152243
  pipeline-multibranch-defaults:1.1
  pipeline-model-declarative-agent:1.1.1
  docker-workflow:1.10
  workflow-durable-task-step:2.11
  pipeline-model-definition:1.1.3
  workflow-basic-steps:2.4
  pipeline-model-api:1.1.3
  pipeline-stage-step:2.2
  cloud-stats:0.11
  pipeline-graph-analysis:1.3
  workflow-aggregator:2.5
  job-restrictions:0.6
  pipeline-stage-view:2.6
)

include_recipe 'osl-jenkins::master'

jenkins_script 'Add Docker Cloud' do
  command <<-EOH.gsub(/^ {4}/, '')
    // Mostly from:
    // https://gist.github.com/stuart-warren/e458c8439bcddb975c96b96bec3971b6
    //
    import jenkins.model.*;
    import hudson.model.*;
    import com.nirima.jenkins.plugins.docker.DockerCloud
    import com.nirima.jenkins.plugins.docker.DockerTemplate
    import com.nirima.jenkins.plugins.docker.DockerTemplateBase
    import com.nirima.jenkins.plugins.docker.launcher.DockerComputerSSHLauncher
    import hudson.plugins.sshslaves.SSHConnector
    import com.cloudbees.plugins.credentials.*
    import com.cloudbees.plugins.credentials.common.*
    import com.cloudbees.plugins.credentials.domains.*
    import com.cloudbees.plugins.credentials.impl.*

    def instance = Jenkins.getInstance()
    if (instance.pluginManager.activePlugins.find { it.shortName == "credentials" } != null) {
      def domain = Domain.global()
      def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

      // Set credentials for docker containers
      dockerUsernameAndPassword = new UsernamePasswordCredentialsImpl(
                  CredentialsScope.GLOBAL,
                  'ssh-docker', // credential ID
                  'Jenkins Slave with Password Configuration',
                  'jenkins', //username
                  'jenkins'  //password
              )
      println '--> adding credentials for ssh slaves'
      store.addCredentials(domain, dockerUsernameAndPassword)

    } else {
      println "--> no credentials plugin installed"
    }

    if (instance.pluginManager.activePlugins.find { it.shortName == "docker-plugin" } != null) {
      DockerTemplateBase templateBase = new DockerTemplateBase(
         'docker-ubuntu', // image
        '', // dnsString
        '', // network
        '/usr/sbin/sshd -D', // dockerCommand
        '', // volumesString
        '', // volumesFromString
        '', // environmentsString
        '', // lxcConfString
        '', // hostname
        2048, // memoryLimit
        2048, // memorySwap
        2, // cpuShares
        '', // bindPorts
        false, // bindAllPorts
        false, // privileged
        false, // tty
        '' // macAddress
      );

      SSHConnector sshConnector = new SSHConnector(
        22,
        'ssh-docker',  //credentialsID for connecting to running container
        null,
        null,
        null,
        null,
        null
      );
      DockerComputerSSHLauncher dkSSHLauncher = new DockerComputerSSHLauncher(sshConnector);

      DockerTemplate dkTemplate = new DockerTemplate(
        templateBase,
        'docker', //labelString
        '', //remoteFs
        '', // remoteFsMapping
        '50', // instanceCapStr
      )

      dkTemplate.setLauncher(dkSSHLauncher);

      ArrayList<DockerTemplate> dkTemplates = new ArrayList<DockerTemplate>();
      dkTemplates.add(dkTemplate);

      ArrayList<DockerCloud> dkCloud = new ArrayList<DockerCloud>();
      dkCloud.add(
        new DockerCloud(
          'docker',
          dkTemplates,
          'tcp://192.168.0.4:2375', // serverUrl
          '400', // containerCapStr
          5, // connectTimeout
          15, // readTimeout
          '', // credentialsId
          ''  // version
        )
      );

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
      "hudson.model.Hudson.Administer",
      "hudson.model.Hudson.Read",
      "hudson.model.Item.Build",
      "hudson.model.Item.Cancel",
      "hudson.model.Item.Configure",
      "hudson.model.Item.Create",
      "hudson.model.Item.Delete",
      "hudson.model.Item.Discover",
      "hudson.model.Item.Read",
      "hudson.model.Item.ViewStatus",
      "hudson.model.Item.Workspace",
      "hudson.model.Run.Delete",
      "hudson.model.Run.Update",
      "hudson.model.View.Configure",
      "hudson.model.View.Create",
      "hudson.model.View.Delete",
      "hudson.model.View.Read"
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
      node.run_state[:jenkins_username] = 'osuosl-manatee' # ~FC001
      node.run_state[:jenkins_password] = items['cli_password'] # ~FC001
    end
  end
end
