function Test-CIEnvironment {
  if ($env:GITHUB_ACTIONS -eq "true") {
    return $true
  }

  if ($env:GITLAB_CI -eq "true") {
    return $true
  }
  
  return $false
}
