module OSLDocker
  module Helper
    # A Groovy snippet that will add a new docker host given a hostname and IP address
    # @param [String] hostname
    # @param [String] IP address
    def add_docker_host(hostname, ip, credentials)
      if credentials.nil?
        <<-EOH.gsub(/^ {4}/, '')
          dkCloud.add(
            new DockerCloud(
              '#{hostname}',
              dkTemplates,
              'tcp://#{ip}:2375', // serverUrl
              '400',                // containerCapStr
              5,                    // connectTimeout
              600,                  // readTimeout
              '',                   // credentialsId
              ''                    // version
            )
          );

        EOH
      else
        <<-EOH.gsub(/^ {4}/, '')
          DockerServerEndpoint endpoint_#{hostname.tr('.', '_')} = new DockerServerEndpoint(
            'tcp://#{ip}:2376',     // uri
            'ibmz_ci_docker-server' // credentials
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
      <<-EOH.gsub(/^ {2}/, '')
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
