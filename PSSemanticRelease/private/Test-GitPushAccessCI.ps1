function Test-GitPushAccessCI {
    param($context)
    
    $remoteUrl = $context.Repository

    # Detect CI environment and set token
    $ciToken = $null

    if ($env:GITLAB_CI -eq "true") {
        if ($env:GITLAB_TOKEN) { $ciToken = $env:GITLAB_TOKEN }
        if ($env:GL_TOKEN) { $ciToken = $env:GL_TOKEN }
    }
    elseif ($env:GITHUB_ACTIONS -eq "true") {
        if ($env:GITHUB_TOKEN) { $ciToken = $env:GITHUB_TOKEN }
        if ($env:GH_TOKEN) { $ciToken = $env:GH_TOKEN }
    }

    # Rewrite HTTPS remote URL for CI using bot username
    if ($ciToken -and $remoteUrl -match '^https://') {
        # Remove existing username if present
        $remoteUrl = $remoteUrl -replace '^https://[^@]+@', ''
        $remoteUrl = "https://ps-semantic-release-bot:$($ciToken)@$($remoteUrl -replace '^https://','')"
        $context.Repository = $remoteUrl
        git remote set-url origin $remoteUrl
    }

    try {
        $output = git push --dry-run origin $($context.Branch) 2>&1

        if ($output -match "Everything up-to-date|To https?://|To git@") {
            Add-ConsoleLog "Allowed to push on branch $($context.Branch) to the Git repository"
            return $true
        }
        else {
            Add-ConsoleLog "Push failed: permission denied."
            return $false
        }
    }
    catch {
        Write-Error $_
        Add-ConsoleLog "Push check failed: $_"
        return $false
    }
}
