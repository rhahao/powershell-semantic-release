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

  foreach ($b in $branches) {
    if ($b -is [string] -and $b -eq $currentBranch) {
      return @{
        Channel     = 'latest'
        Prerelease  = $false
        Branch      = $currentBranch
      }
    }

    if ($b.name -eq $currentBranch) {
      return @{
        Channel     = $b.prerelease
        Prerelease  = $true
        Branch      = $currentBranch
      }
    }
  }

  Write-Host "Branch $currentBranch is not a release branch"
  return $null
}