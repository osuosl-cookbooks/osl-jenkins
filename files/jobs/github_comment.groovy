job('github_comment') {
  description("Send a comment to a specified Github PR")
  parameters {
    stringParam("repo", "\"\"", "")
    stringParam("pr_id", "\"\"", "")
    stringParam("message", "\"\"", "")
  }
  wrappers {
    ghprbUpstreamStatus {
      showMatrixStatus(false)
      commitStatusContext(null)
      triggeredStatus(null)
      startedStatus(null)
      statusUrl(null)
      addTestResults(false)
    }
    credentialsBinding {
      usernamePassword {
        credentialsId('cookbook_uploader')
        usernameVariable(null)
        passwordVariable('GITHUB_TOKEN')
      }
    }
  }
  steps {
    shell("/var/lib/jenkins/bin/github_comment.rb \$repo \$pr_id \"\$message\"")
  }
}
