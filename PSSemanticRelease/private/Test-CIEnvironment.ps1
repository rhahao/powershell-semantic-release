function Test-CIEnvironment {
  return $env:GITLAB_CI -eq "true" -or $env:GITHUB_ACTIONS -eq "true"
}
