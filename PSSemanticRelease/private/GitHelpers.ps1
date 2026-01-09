function Get-GitStatus {
    return git status --porcelain
}

function Get-BranchDefault {
    $defaultBranch = git remote show origin | Select-String 'HEAD branch' | ForEach-Object { ($_ -split ':')[1].Trim() }
    
    return $defaultBranch
}
function Get-CurrentBranch {
    $currentBranch = git rev-parse --abbrev-ref HEAD
    return $currentBranch
}

function Get-CommitUrl {
    param (
        [string]$RepositoryUrl,
        [string]$Sha
    )

    if ($RepositoryUrl -match 'github\.com') {
        return "$RepositoryUrl/commit/$Sha"
    }

    if ($RepositoryUrl -match 'gitlab\.com') {
        return "$RepositoryUrl/-/commit/$Sha"
    }

    return $null
}

function Get-CompareUrl {
    param (
        [string]$RepositoryUrl,
        [string]$FromVersion,
        [string]$ToVersion
    )

    if (-not $RepositoryUrl) { return $null }

    if ($RepositoryUrl -match 'github\.com') {
        return "$RepositoryUrl/compare/v$FromVersion...v$ToVersion"
    }

    if ($RepositoryUrl -match 'gitlab\.com') {
        return "$RepositoryUrl/-/compare/v$FromVersion...v$ToVersion"
    }

    return $null
}

function Get-ConventionalCommits {
    param($context)

    $Branch = $context.Repository.BranchCurrent

    $lastTag = git describe --tags --abbrev=0 $Branch 2>$null

    $range = if ($lastTag) { "$lastTag..$Branch" } else { $Branch }

    $commits = @()

    foreach ($line in git log $range --pretty=format:'%H|%s' --reverse) {
        $commit = ConvertFrom-Commit $line
        if ($commit) { $commits += $commit }
    }

    return , $commits
}

function Get-CurrentSemanticVersion {
    param (
        $context,
        $Branch = "HEAD"
    )

    git fetch --tags --quiet

    if ($context.Config.Project.unify_tag) {
        $lastTag = git tag --list | Sort-Object { [version]($_ -replace '^v', '') } -Descending | Select-Object -First 1
    }
    else {
        $lastTag = git describe --tags --abbrev=0 $Branch 2>$null
    }

    return $lastTag -replace '^v', ''
}

function Get-GitRemoteUrl {
    git remote get-url origin
}

function Test-GitPushAccessCI {
    param($context, $token)
    
    $remoteUrl = $context.Repository.RemoteUrl

    # Rewrite HTTPS remote URL for CI using bot username
    if ($token -and $remoteUrl -match '^https://') {
        # Remove existing username if present
        $remoteUrl = $remoteUrl -replace '^https://[^@]+@', ''
        $remoteUrl = "https://pwsh-semantic-release-bot:$($token)@$($remoteUrl -replace '^https://','')"
        $context.Repository.RemoteUrl = $remoteUrl
        git remote set-url origin $remoteUrl
    }

    try {
        $currentBranch = $context.Repository.BranchCurrent

        $output = git push --dry-run origin $currentBranch 2>&1

        if ($output -match "Everything up-to-date|To https?://|To git@") {
            Add-ConsoleLog "Allowed to push on branch $currentBranch to the Git repository"
        }
        else {
            Add-ConsoleLog "Push failed: permission denied."
        }
    }
    catch {
        throw "Push check failed: $_"
    }
}

function Test-GitTagExist {
    param ([string]$tag)

    git rev-parse -q --verify "refs/tags/$tag" *> $null
    return $LASTEXITCODE -eq 0
}

function Set-GitIdentity {
    $commiterEmail = $env:GIT_AUTHOR_EMAIL

    if ($null -eq $commiterEmail) {
        $commiterEmail = "253679957+ps-semantic-release-bot@users.noreply.github.com"
    }

    $commiterName = $env:GIT_AUTHOR_NAME

    if ($null -eq $commiterName) {
        $commiterName = "pwsh-semantic-release-bot"
    }

    try {
        git config user.email $commiterEmail 2>$null
        git config user.name $commiterName 2>$null
    }
    catch {
        throw $_
    }
}

function New-GitTag {
    param ($context)

    try {
        $version = $context.NextRelease.Version

        $tag = "v$Version"

        if (Test-GitTagExist $tag) {
            throw "Tag $tag already exists"
        }

        if ($context.DryRun) {
            Add-ConsoleLog "Skip $tag tag creation in DryRun mode"
            $global:LASTEXITCODE = 0
        }
        else {
            git tag $tag 2>$null
            git push origin $tag --quiet
        }
    }
    catch {
        throw $_
    }    
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

    if ($context.NextRelease.Channel -ne "default" -and -not $context.Config.Project.unify_tag) {
        $tags = git tag | Where-Object { $_ -match "^v$nextVersion-$($context.NextRelease.Channel)\.\d+$" }

        if (-not $tags) {
            $nextVersion = "$nextVersion-$($context.NextRelease.Channel).1"
        }
        else {
            $last = ($tags | ForEach-Object { [int]($_ -replace ".*-$($context.NextRelease.Channel)\.", "") } | Sort-Object | Select-Object -Last 1)

            $nextVersion = "$nextVersion-$($context.NextRelease.Channel).$($last + 1)"
        }
    }

    $versionChannel = if ($context.NextRelease.Channel -ne "default") { "$($context.NextRelease.Channel) " }
    
    if ($null -eq $context.CurrentVersion.Published) {
        Add-ConsoleLog "There is no previous $($versionChannel)release, the next release version is $nextVersion"
    }
    else {
        Add-ConsoleLog "The next $($versionChannel)release version is $nextVersion"
    }

    $context.NextRelease.Version = $nextVersion
}

function Get-GitModifiedFiles {
    return git ls-files -m -o
}