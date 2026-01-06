function Confirm-ReleaseBranch {
  $config = Get-SemanticReleaseConfig
  $currentBranch = git rev-parse --abbrev-ref HEAD

  $branches = @()
  
  if ($null -eq $config.branches) {
    $branches += "main"
  }
  else {
    $branches += $config.branches
  }

  if ($branches -notcontains $currentBranch) {
    Write-Host "Branch $currentBranch is not a release branch"
    return $false
  }

  return $currentBranch
}