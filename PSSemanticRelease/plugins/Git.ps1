class Git {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    Git([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] VerifyConditions() {
        $typeName = $this.GetType().Name
        $step = "VerifyConditions"

        Add-ConsoleLog "Start step $step of plugin $typeName"

        $gitStatus = Get-GitStatus

        if ($gitStatus) {
            throw "[Git] Working tree is not clean. Commit or stash changes before releasing."
        }

        $assets = $this.Config.assets
        $message = $this.Config.message

        if (-not $assets -or ($assets -is [array] -and $assets.Count -eq 0)) {
            throw "[Git] At least one asset needs to be specified."
        }

        if (-not $message) {
            throw "[Git] A commit message needs to be specified."
        }

        if (-not $this.Context.DryRun) {
            Set-GitIdentity
        }

        $currentVersion = Get-CurrentSemanticVersion -context $this.Context.Config.Project.unifyTag
        $this.Context.CurrentVersion.Branch = $currentVersion

        if (-not $currentVersion) {
            Add-ConsoleLog "No previous release found, retrieving all commits"
        }
        else {
            Add-ConsoleLog "Found git tag v$currentVersion on branch $($this.Context.Repository.BranchCurrent)"
        }

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }

    [void] Prepare() {
        $dryRun = $this.Context.DryRun
        $typeName = $this.GetType().Name
        $step = "Prepare"

        if ($dryRun) { 
            Add-ConsoleLog "Skip step `"$step`" of plugin `"$typeName`" in DryRun mode"
            return
        }

        Add-ConsoleLog "Start step $step of plugin $typeName"

        $assets = , $this.Config.assets
        $messageTemplate = $this.Config.message

        $lists = @()
        $modifiedFiles = Get-GitModifiedFiles

        foreach ($file in $modifiedFiles) {
            foreach ($pathRule in $assets) {
                if ($file -like $pathRule) {
                    $found = Get-Item -Path $file
                    $lists += $found.FullName
                    break
                }
            }
        }

        if ($lists.Count -eq 0) { 
            Add-ConsoleLog "[Git] Cannot find files listed in assets config"
            return
        }

        Add-ConsoleLog "[Git] Found $($lists.Count) file(s) to commit"

        # Stage files
        git add $lists 2>$null

        git restore .
        git restore --staged .

        git add $lists 2>$null

        $commitMessage = Expand-ContextString -context $this.Context -template $messageTemplate

        git commit -m $commitMessage --quiet

        $version = $this.Context.NextRelease.Version

        $tag = "v$Version"

        if (Test-GitTagExist $tag) {
            throw "Tag $tag already exists"
        }

        if ($dryRun) {
            Add-ConsoleLog "Skip $tag tag creation in DryRun mode"
        }
        else {
            git tag $tag 2>$null
            git push origin $tag --quiet
        }

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }

    [void] Publish() {
        $dryRun = $this.Context.DryRun
        $typeName = $this.GetType().Name
        $step = "Publish"

        if ($dryRun) { 
            Add-ConsoleLog "Skip step `"$step`" of plugin `"$typeName`" in DryRun mode"
            return
        }

        Add-ConsoleLog "Start step $step of plugin $typeName"
        
        $currentBranch = $this.Context.Repository.BranchCurrent
        $nextVersion = $this.Context.NextRelease.Version

        git push origin $currentBranch --quiet

        Add-ConsoleLog "[Git] Prepared Git release: v${nextVersion}"

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }
}