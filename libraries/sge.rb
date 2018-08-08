module OSLSGE
  module Helper
    # rubocop:disable Metrics/ParameterLists
    def header_sge_cloud
      <<-EOH.gsub(/^ {8}/, '')
        import org.jenkinsci.plugins.sge.*
        import jenkins.model.*
        import hudson.model.*;

        def instance = Jenkins.getInstance()
      EOH
    end

    def add_sge_cloud(name, queue, label, hostname, username, password, port)
      <<-EOH.gsub(/^ {8}/, '')

        BatchCloud sge_#{name.tr('-', '_')} = new BatchCloud(
          '#{name}',    // cloudName
          '#{queue}',   // queueType
          '#{label}',   // label
          1440,         // maximumIdleMinutes
          '#{hostname}', // hostname
          #{port},      // port
          '#{username}', // username
          '#{password}' // password
        )

        instance.clouds.add(sge_#{name.tr('-', '_')});
      EOH
    end
  end
end
