function Confirm-GitClean {
    $status = git status --porcelain

    if ($status) {
        throw "Git working tree is not clean. Commit or stash changes before releasing."
    }
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

    $results = @()

    foreach ($line in git log $range --pretty=format:'%H|%s' --reverse) {
        $commit = ConvertFrom-Commit $line
        if ($commit) { $results += $commit }
    }

    $commits = , $results

    $context.Commits.List = $commits
    $context.Commits.Formatted = if ($commits.Count -eq 1) { "1 commit" } else { "$($commits.Count) commits" }
}

function Get-CurrentSemanticVersion {
    param (
        $context,
        $Branch = "HEAD"
    )

    git fetch --tags --quiet

    if ($context.Config.unify_tag) {
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
    param($context)
    
    $remoteUrl = $context.Repository.RemoteUrl

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
        $remoteUrl = "https://pwsh-semantic-release-bot:$($ciToken)@$($remoteUrl -replace '^https://','')"
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

function Push-GitAssets {
    param($context)

    $gitConfig = $Context.Config.git

    if (-not $gitConfig) { return }

    $assets = $gitConfig.assets
    $messageTemplate = $gitConfig.message

    if (-not $assets -or -not $messageTemplate) { return }

    $assets = , $assets

    if ($assets.Length -eq 0) { return }

    $lists = @()

    foreach ($asset in $assets) {
        $found = Get-Item -Path $asset -ErrorAction SilentlyContinue

        if (-not $found) { continue }

        $lists += $found.FullName
    }

    if ($lists.Length -eq 0) { return }

    $filesCount = 0

    foreach ($asset in $assets) {
        $path = Get-Item -Path $asset

        if ($path.PSIsContainer) {
            $filesCount += (Get-ChildItem -Path $asset -File -Recurse).Count
        }
        else {
            $filesCount++
        }
    }

    Add-ConsoleLog "Found $filesCount file(s) to commit"

    # Stage files
    git add $lists 2>$null

    git restore .
    git restore --staged .

    git add $lists 2>$null

    $commitMessage = Expand-ContextString -context $context -template $messageTemplate

    git commit -m $commitMessage --quiet
    git push origin $Context.Branch --quiet
}

function New-GitTag {
    param ($version)

    try {
        $tag = "v$Version"

        if (Test-GitTagExist $tag) {
            throw "tag $tag already exists"
        }

        if ($Context.DryRun) {
            Add-ConsoleLog "Skip $tag tag creation in DryRun mode"
            return
        }

        git tag $tag 2>$null
        git push origin $tag --quiet
    }
    catch {
        throw $_
    }    
}
