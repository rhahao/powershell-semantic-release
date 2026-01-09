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

function Get-NextSemanticVersion {
    param ($context)

    $nextVersion = ""

    if ($null -eq $context.CurrentVersion.Published) {
        $nextVersion = "1.0.0"
    }
    else {
        $v = [version]$context.CurrentVersion.Published
        $Type = $context.NextRelease.Type

        if ($Type -eq 'major') {
            $nextVersion = "{0}.0.0" -f ($v.Major + 1)
        }
        elseif ($Type -eq 'minor') {
            $nextVersion = "{0}.{1}.0" -f $v.Major, ($v.Minor + 1)
        }
        elseif ($Type -eq 'patch') {
            $nextVersion = "{0}.{1}.{2}" -f $v.Major, $v.Minor, ($v.Build + 1)
        }
    }    

    if ($context.NextRelease.Channel -ne "default" -and -not $context.Config.unify_tag) {
        $tags = git tag | Where-Object { $_ -match "^v$nextVersion-$($context.NextRelease.Channel)\.\d+$" }

        if (-not $tags) {
            $nextVersion = "$nextVersion-$($context.NextRelease.Channel).1"
        }
        else {
            $last = ($tags | ForEach-Object { [int]($_ -replace ".*-$($context.NextRelease.Channel)\.", "") } | Sort-Object | Select-Object -Last 1)

            $nextVersion = "$nextVersion-$($context.NextRelease.Channel).$($last + 1)"
        }
    }

    $versionChannel = if ($context.NextRelease.Channel -ne "lastest") { "$($context.NextRelease.Channel) " }
    
    if ($null -eq $context.CurrentVersion.Published) {
        Add-ConsoleLog "There is no previous $($versionChannel)release, the next release version is $nextVersion"
    }
    else {
        Add-ConsoleLog "The next $($versionChannel)release version is $nextVersion"
    }

    return $nextVersion
}