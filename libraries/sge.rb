module OSLSGE
  module Helper
    # rubocop:disable Metrics/ParameterLists
    def add_sge_cloud(name, queue, label, hostname, username, password, port)
      <<-EOH.gsub(/^ {8}/, '')
        import org.jenkinsci.plugins.sge.*
        import jenkins.model.*
        import hudson.model.*;

        def instance = Jenkins.getInstance()

        BatchCloud sge = new BatchCloud(
          '#{name}',    // cloudName
          '#{queue}',   // queueType
          '#{label}',   // label
          1440,         // maximumIdleMinutes
          '#{hostname}', // hostname
          #{port},      // port
          '#{username}', // username
          '#{password}' // password
        )

        instance.clouds.add(sge);
      EOH
    end
  end
end
