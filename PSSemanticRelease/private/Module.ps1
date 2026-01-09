function Get-PSSemanticReleaseVersion {
    $version = Get-Module -Name PSSemanticRelease | Select-Object -First 1 -ExpandProperty Version
    return $version.ToString()
}

function Get-ReleaseProvider {
    if ($env:GITHUB_ACTIONS -eq "true") { return "github" }
    
    if ($env:GITLAB_CI -eq "true") { return "gitlab" }

    return $null
}

function Get-ReleaseTypeFromCommits {
    param($context)

    $types = @()

    foreach ($commit in $context.Commits.List) {
        Add-ConsoleLog "Analyzing commit: $($commit.Message)"

        $commitType = $context.Config.releaseRules | Where-Object { $_.type -eq $commit.Type }

        if ($null -eq $commitType) {
            Add-ConsoleLog "The commit should not trigger a release"
        }
        else {
            if ($commit.Breaking -eq $true) {
                Add-ConsoleLog "The release type for the commit is major"
                $types += "major"
            }
            else {
                Add-ConsoleLog "The release type for the commit is $($commitType.release)"
                $types += $commitType.release
            }            
        }
    }

    $type = $types | Sort-Object -Unique

    if ($type -contains "major") {
        $type = $type | Where-Object { $_ -eq "major" }
    }

    if ($type -contains "minor") {
        $type = $type | Where-Object { $_ -eq "minor" }
    }

    if ($type -contains "patch") {
        $type = $type | Where-Object { $_ -eq "patch" }
    }

    $releaseType = if ($null -eq $type) { "no release needed" } else { "$type release" }

    Add-ConsoleLog "Analysis of $($context.Commits.Formatted) completed: $releaseType"

    return $type
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

