function Test-CIEnvironment {
  Write-Host $env:GITHUB_ACTIONS
  return $env:GITLAB_CI -eq "true" -or $env:GITHUB_ACTIONS -eq "true"
}
