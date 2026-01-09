function Test-CIEnvironment {
    if ($env:GITHUB_ACTIONS -eq "true") {
        return $true
    }

    if ($env:GITLAB_CI -eq "true") {
        return $true
    }
  
    return $false
}

function Get-PSSemanticReleaseVersion {
    $version = Get-Module -Name PSSemanticRelease | Select-Object -First 1 -ExpandProperty Version
    return $version.ToString()
}

function Get-ReleaseProvider {
    if ($env:GITHUB_ACTIONS -eq "true") { return "github" }
    
    if ($env:GITLAB_CI -eq "true") { return "gitlab" }

    return $null
}

function Publish-Release {
    param($Context)

    if ($Context.DryRun) {
        Add-ConsoleLog "Dry-run: release not published"
        return
    }

    $provider = Get-ReleaseProvider

    if ($null -eq $provider) {
        Add-ConsoleLog "Creating release aborted on unsupported CI provider"
        return
    }

    if ($provider -eq "github") {
        New-GitHubRelease -context $context
    }

    if ($provider -eq "gitlab") {
        New-GitLabRelease -context $context
    }

    Add-ConsoleLog "Published release $($context.NextRelease.Version) on $($context.NextRelease.Channel) channel"
}