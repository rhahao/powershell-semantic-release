function Confirm-EnvironmentCI {
  if ($env:GITLAB_CI -eq "true") {
    if (-not $env:GITLAB_TOKEN -and -not $env:GL_TOKEN) {
      throw "No GitLab token (GITLAB_TOKEN or GL_TOKEN) found in CI environment."
    }
  }
  elseif ($env:GITHUB_ACTIONS -eq "true") {
    if (-not $env:GITHUB_TOKEN -and -not $env:GH_TOKEN) {
      throw "No GitHub token (GITHUB_TOKEN or GH_TOKEN) found in CI environment."
    }
  }
}
