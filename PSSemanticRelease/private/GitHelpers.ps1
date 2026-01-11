function Get-GitStatus {
    return git status --porcelain
}

function Get-GitModifiedFiles {
    return git ls-files -m -o
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

function Get-GitTagHighest {
    git fetch --tags --quiet

    $tags = git tag 2>$null

    if (-not $tags) { return $null }

    $versions = foreach ($tag in $tags) {
        $clean = $tag -replace '^v', ''

        if ($clean -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
            continue
        }

        try {
            [version]$clean
        }
        catch {
            continue
        }
    }

    if (-not $versions) { return $null }

    return $versions | Sort-Object | Select-Object -Last 1
}

function Get-CurrentSemanticVersion {
    param ($UnifyTag)

    if (-not $UnifyTag) {
        git fetch --tags --quiet
        $lastTag = git describe --tags --abbrev=0 HEAD 2>$null
        return $lastTag -replace '^v', ''
    }
    else {
        $version = Get-GitTagHighest

        if ($null -eq $version) {
            return $version.ToString()
        }

        return $version
    }    
}

function Get-GitRemoteUrl {
    git remote get-url origin
}

function Test-GitPushAccessCI {
    param($context, $token)
    
    try {
        $remoteUrl = $context.Repository.RemoteUrl

        # Rewrite HTTPS remote URL for CI using bot username
        if ($token -and $remoteUrl -match '^https://') {
            # Remove existing username if present
            $remoteUrl = $remoteUrl -replace '^https://[^@]+@', ''
            $remoteUrl = "https://pwsh-semantic-release-bot:$($token)@$($remoteUrl -replace '^https://','')"
            $context.Repository.RemoteUrl = $remoteUrl
            git remote set-url origin $remoteUrl
        }
    
        $currentBranch = $context.Repository.BranchCurrent

        $output = git push --dry-run origin $currentBranch 2>&1

        if ($output -match "Everything up-to-date|To https?://|To git@") {
            return "Allowed to push on branch $currentBranch to the GitHub repository"
        } else {
            throw "Push failed: permission denied."
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

function Get-NextSemanticVersion {
    param ($context)

    $currentVersion = ""
    $nextVersion = ""
    $channel = $context.NextRelease.Channel
    $unifyTag = $context.Config.Project.unifyTag
    $highestTag = Get-GitTagHighest

    if ($channel -eq "default" -or $unifyTag) {
        $currentVersion = $highestTag
    }
    else {
        $branchVersion = Get-BaseSemanticVersion $context.CurrentVersion.Branch

        if (-not $branchVersion) {
            $currentVersion = $highestTag
        }
        elseif ($branchVersion -lt $highestTag) {
            $currentVersion = $highestTag
        }
        else {
            $currentVersion = $branchVersion
        }
    }

    if (-not $currentVersion) {
        $nextVersion = "1.0.0"
    }

    if ($currentVersion) {
        if ($channel -eq "default" -or $unifyTag) {
            $Type = $context.NextRelease.Type

            $v = [version]$currentVersion

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
        else {
            $nextVersion = $currentVersion

            $tags = git tag | Where-Object { $_ -match "^v$nextVersion-$($channel)\.\d+$" }

            if (-not $tags) {
                $nextVersion = "$nextVersion-$($channel).1"
            }
            else {
                $last = ($tags | ForEach-Object { [int]($_ -replace ".*-$($channel)\.", "") } | Sort-Object | Select-Object -Last 1)

                $nextVersion = "$nextVersion-$($channel).$($last + 1)"
            }
        }
    }
    
    return $nextVersion
}