function Get-GitModifiedFiles {
    return git ls-files -m -o
}

function Get-GitBranchCurrent {
    return git rev-parse --abbrev-ref HEAD 2>$null
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
    $lastTag = try {
        git describe --tags --abbrev=0 HEAD 2>$null
    }
    catch {
        $null
    }

    $range = if ($lastTag) { "$lastTag..HEAD" } else { 'HEAD' }

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
    if (-not $env:CI_SERVER_HOST -or -not $env:CI_PROJECT_PATH) {
        return git config --get remote.origin.url
    }

    return "git@$($env:CI_SERVER_HOST):$($env:CI_PROJECT_PATH).git"
}

function Get-GitOriginRemoteUrl {
    return git config --get remote.origin.url
}

function Test-GitPushAccess {
    param($context)
    
    try {
        $remoteUrl = $context.Repository.OriginRemoteUrl
        $token = $context.EnvCI.Token

        # Rewrite remote URL for CI using bot username
        if ($token) {
            if (-not $env:CI_SERVER_HOST -or -not $env:CI_PROJECT_PATH) {
                if ($remoteUrl -match '^https://') {
                    # Remove existing username if present
                    $remoteUrl = $remoteUrl -replace '^https://[^@]+@', ''
                    $remoteUrl = "https://pwsh-semantic-release-bot:$($token)@$($remoteUrl -replace '^https?://','')"
                    $context.Repository.OriginRemoteUrl = $remoteUrl
                    git remote set-url origin $remoteUrl         
                }    
            }
            else {                
                $remoteUrl = "https://pwsh-semantic-release-bot:$($token)@$($env:CI_SERVER_HOST)/$($env:CI_PROJECT_PATH)"
                $context.Repository.OriginRemoteUrl = $remoteUrl
                git remote set-url origin $remoteUrl
            }
        }
    
        $currentBranch = $context.Repository.BranchCurrent
        
        git push --dry-run --no-verify --quiet origin $currentBranch 2>$null
    }
    catch {
        throw "Push check failed: $_"
    }
}

function Test-GitTagExist {
    param ([string]$tag)

    git rev-parse -q --verify "refs/tags/$tag" *>$null
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

    $channel = $context.NextRelease.Channel
    $unifyTag = $context.Config.Project.unifyTag
    $highestTag = Get-GitTagHighest
    $isPrerelease = $channel -ne "default" -and -not $unifyTag

    if ($isPrerelease) {
        $branchVersion = Get-BaseSemanticVersion $context.CurrentVersion.Branch
        $escapedChannel = [regex]::Escape($channel)
        $isCurrentPrerelease = $context.CurrentVersion.Branch -match "-$escapedChannel\.\d+$"
        $isAheadOfStable = -not $highestTag -or $branchVersion -gt $highestTag

        if ($branchVersion -and $isCurrentPrerelease -and $isAheadOfStable) {
            $nextVersion = $branchVersion.ToString()
        }
        else {
            $nextVersion = Get-BumpedSemanticVersion -Version $highestTag -Type $context.NextRelease.Type
        }

        $tags = git tag | Where-Object { $_ -match "^v$nextVersion-$escapedChannel\.\d+$" }

        if (-not $tags) {
            return "$nextVersion-$channel.1"
        }

        $last = $tags |
            ForEach-Object { [int]($_ -replace ".*-$escapedChannel\.", "") } |
            Sort-Object |
            Select-Object -Last 1

        return "$nextVersion-$channel.$($last + 1)"
    }

    return Get-BumpedSemanticVersion -Version $highestTag -Type $context.NextRelease.Type
}

function Get-BumpedSemanticVersion {
    param (
        [version]$Version,
        [string]$Type
    )

    if (-not $Version) {
        return "1.0.0"
    }

    if ($Type -eq 'major') {
        return "{0}.0.0" -f ($Version.Major + 1)
    }

    if ($Type -eq 'minor') {
        return "{0}.{1}.0" -f $Version.Major, ($Version.Minor + 1)
    }

    if ($Type -eq 'patch') {
        return "{0}.{1}.{2}" -f $Version.Major, $Version.Minor, ($Version.Build + 1)
    }
}
function Test-GitRepository {
    if (-not (Test-Path .git)) {
        Add-FatalLog "Not a Git repository"
    }
}

function New-GitTag {
    param($context)

    $version = $context.NextRelease.Version
    $unifyTag = $context.Config.Project.unifyTag

    $gitConfig = $context.Config.Project.plugins | Where-Object { $_.Name -eq "@ps-semantic-release/Git" }
    $messageTemplate = $gitConfig.Config.message
    $assets = $gitConfig.Config.assets
    $noAsset = $assets.Count -eq 0

    $tag = "v$Version"

    if (Test-GitTagExist $tag) {
        throw "Tag $tag already exists"
    }

    if ($unifyTag -or $noAsset) {        
        $commitMessage = Expand-ContextString -context $context -template $messageTemplate

        $zwsp = [char]0x200B
        $tagAnnotation = $commitMessage -replace '(?m)^#', "$zwsp#"

        git tag -a $tag -m $tagAnnotation
    }
    else {
        git tag $tag HEAD
    }    
}

function Push-GitTag {
    param($tag)

    git push origin $tag *>$null
}
