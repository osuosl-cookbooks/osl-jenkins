cookbook_file '/tmp/jenkin_is_ready.rb' do
  source 'jenkin_is_ready.rb'
  mode '0755'
end

jenkins_script 'Set anonymous to Admin' do
  command <<-EOH.gsub(/^ {4}/, '')
    import jenkins.*
    import hudson.*
    import hudson.model.*
    import jenkins.model.*
    import hudson.security.*
    def instance = Jenkins.getInstance()
    def strategy = new GlobalMatrixAuthorizationStrategy()
    strategy.add(Jenkins.ADMINISTER, "anonymous")
    instance.setAuthorizationStrategy(strategy)
    instance.save()
  EOH
end
