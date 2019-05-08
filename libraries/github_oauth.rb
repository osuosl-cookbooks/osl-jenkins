module OSLGithubOauth
  module Helper
    def add_github_oauth(
      client_id,
      client_secret,
      admin_users,
      normal_users
    )
      <<-EOH.gsub(/^ {8}/, '')
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
          "com.cloudbees.plugins.credentials.CredentialsProvider.Create",
          "com.cloudbees.plugins.credentials.CredentialsProvider.Delete",
          "com.cloudbees.plugins.credentials.CredentialsProvider.Update",
          "com.cloudbees.plugins.credentials.CredentialsProvider.View",
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
  end
end
