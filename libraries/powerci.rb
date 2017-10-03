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
  end
end
