module Powerci
  module Helper
    # A Groovy snippet that will add a new docker host given a hostname and IP address
    # @param [String] hostname
    # @param [String] IP address
    def add_docker_host(hostname, ip)
      <<-EOH.gsub(/^ {2}/, '')
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
    end

    # A Groovy snippet that will add new docker images
    # @param [String] image name
    # @param [String] ssh public key to inject into the image
    # @param [Integer] docker memory limit
    # @param [Integer] docker memory swap
    # @param [Integer] docker cpu shared
    def add_docker_image(image, docker_public_key, memory_limit, memory_swap, cpu_shared)
      var_name = image.tr('/:\-.', '_')
      <<-EOH.gsub(/^ {2}/, '')
        DockerTemplateBase #{var_name}_TemplateBase = new DockerTemplateBase(
           '#{image}', // image
          '',     // dnsString
          '',     // network
          '',     // dockerCommand
          '',     // volumesString
          '',     // volumesFromString
          'JENKINS_SLAVE_SSH_PUBKEY=#{docker_public_key}', // environmentsString
          '',     // lxcConfString
          '',     // hostname
          #{memory_limit},   // memoryLimit
          #{memory_swap},   // memorySwap
          #{cpu_shared},      // cpuShares
          '',     // bindPorts
          false,  // bindAllPorts
          false,  // privileged
          false,  // tty
          ''      // macAddress
        );
        DockerTemplate dk_#{var_name}_Template = new DockerTemplate(
          #{var_name}_TemplateBase,
          '#{image}', //labelString
          '', //remoteFs
          '', // remoteFsMapping
          '50', // instanceCapStr
        )
        dk_#{var_name}_Template.setLauncher(dkSSHLauncher);
        dkTemplates.add(dk_#{var_name}_Template);

      EOH
    end
  end
end
