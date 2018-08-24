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
