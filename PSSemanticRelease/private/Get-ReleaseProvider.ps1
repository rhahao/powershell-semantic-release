function Get-ReleaseProvider {
    if ($env:GITHUB_ACTIONS -eq "true") { return "github" }
    
    if ($env:GITLAB_CI -eq "true") { return "gitlab" }

    return $null
}