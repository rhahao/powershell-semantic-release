function Confirm-EnvironmentCI {
  if ($env:GITLAB_CI -eq "true") {
    if (-not $env:GITLAB_TOKEN -and -not $env:GL_TOKEN) {
      throw "No GitLab token found in CI environment."
    }
  }
  elseif ($env:GITHUB_ACTIONS -eq "true") {
    if (-not $env:GITHUB_TOKEN -and -not $env:GH_TOKEN) {
      throw "No GitHub token found in CI environment."
    }
  }
}
