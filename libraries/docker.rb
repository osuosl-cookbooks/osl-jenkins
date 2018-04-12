module OSLDocker
  module Helper
    # A Groovy snippet that adds a collection of Docker clouds into Jenkins
    # @param [String] groovy snippet of docker images
    # @param [String] groovy snippet of docker hosts
    # rubocop:disable Metrics/ParameterLists
    def add_docker_cloud(docker_images, docker_hosts, docker_client_key, docker_client_cert, docker_client_chain,
                         ssh_cred_id, docker_cred_id)
      docker_tls =
        unless docker_client_key.nil? && docker_client_cert.nil? && docker_client_chain.nil?
          <<-EOH.gsub(/^ {2}/, '')

            // Find docker host credentials
            id_matcher_server = CredentialsMatchers.withId('#{docker_cred_id}')
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
                  "#{docker_cred_id}",
                  "Docker client certificate",
                  "#{docker_client_key.gsub("\n", '\n')}",
                  "#{docker_client_cert.gsub("\n", '\n')}",
                  "#{docker_client_chain.gsub("\n", '\n')}"
                  )
              CredentialsProvider.lookupStores(instance).iterator().next().addCredentials(
                Domain.global(),
                credentials_docker_host
              )
            }
          EOH
        end
      <<-EOH.gsub(/^ {8}/, '')
        // Mostly from:
        // https://gist.github.com/stuart-warren/e458c8439bcddb975c96b96bec3971b6
        // https://gist.github.com/adrianlzt/d092b5852600b19c08d2d704c8633e09
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
        if (instance.pluginManager.activePlugins.find { it.shortName == "docker-plugin" } != null &&
            instance.pluginManager.activePlugins.find { it.shortName == "docker-commons" } != null) {
          #{docker_tls}
          // Find ssh credentials
          id_matcher = CredentialsMatchers.withId('#{ssh_cred_id}')
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
            println("ERROR: Unable to find #{ssh_cred_id} credentials")
            return
          }

          // Setup ssh to docker nodes using our #{ssh_cred_id} credentials
          SshHostKeyVerificationStrategy strategy = new NonVerifyingKeyVerificationStrategy()
          DockerComputerSSHConnector sshConnector =
            new DockerComputerSSHConnector(
              new DockerComputerSSHConnector.ManuallyConfiguredSSHKey('#{ssh_cred_id}', strategy)
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

    # A Groovy snippet that will add a new docker host given a hostname and IP address
    # @param [String] hostname
    # @param [String] IP address
    def add_docker_host(hostname, ip, credentials)
      if credentials.nil?
        <<-EOH
          DockerServerEndpoint endpoint_#{hostname.tr('.', '_')} = new DockerServerEndpoint(
            'tcp://#{ip}:2375',     // uri
            ''                      // credentials
          )
          dkCloud.add(
            new DockerCloud(
              '#{hostname}',
              dkTemplates,
              endpoint_#{hostname.tr('.', '_')}, // endpoint
              400,                  // containerCapStr
              5,                    // connectTimeout
              600,                  // readTimeout
              '',                   // version
              ''                    // dockerHostname
            )
          );

        EOH
      else
        <<-EOH
          DockerServerEndpoint endpoint_#{hostname.tr('.', '_')} = new DockerServerEndpoint(
            'tcp://#{ip}:2376',     // uri
            '#{credentials}'        // credentials
          )
          dkCloud.add(
            new DockerCloud(
              '#{hostname}',
              dkTemplates,
              endpoint_#{hostname.tr('.', '_')}, // endpoint
              400,                  // containerCapStr
              5,                    // connectTimeout
              600,                  // readTimeout
              '',                   // version
              ''                    // dockerHostname
            )
          );

        EOH
      end
    end

    # A Groovy snippet that will add new docker images
    # @param [String] image name
    # @param [String] ssh public key to inject into the image
    # @param [Integer] docker memory limit
    # @param [Integer] docker memory swap
    # @param [Integer] docker cpu shared
    def add_docker_image(image, docker_public_key, memory_limit, memory_swap, cpu_shared)
      # Convert docker image name into something that works as a Groovy variable name
      var_name = image.tr('/:\-.', '_')
      # Convert docker image name into a more sensible jenkins label converting slashes and colons to dashes
      label = "docker-#{image.tr('/:', '-')}"
      <<-EOH
          DockerTemplateBase #{var_name}_TemplateBase = new DockerTemplateBase(
             '#{image}', // image
            '',     // pullCredentialsId
            '',     // dnsString
            '',     // network
            '',     // dockerCommand
            '',     // volumesString
            '',     // volumesFromString
            'JENKINS_SLAVE_SSH_PUBKEY=#{docker_public_key}', // environmentsString
            '',     // hostname
            #{memory_limit},   // memoryLimit
            #{memory_swap},   // memorySwap
            #{cpu_shared},      // cpuShares
            '',     // bindPorts
            false,  // bindAllPorts
            false,  // privileged
            false,  // tty
            '',     // macAddress
            ''      // extraHostsString
          );
          DockerTemplate dk_#{var_name}_Template = new DockerTemplate(
            #{var_name}_TemplateBase, // dockerTemplateBase
            sshConnector,   // connector
            '#{label}',     // labelString
            '',             // remoteFs
            '50',           // instanceCapStr
          )
          dkTemplates.add(dk_#{var_name}_Template);

      EOH
    end
  end
end
