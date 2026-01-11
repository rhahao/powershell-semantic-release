class Git {
    [string]$PluginName
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    Git([string]$PluginName, [PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] VerifyConditions() {
        $typeName = "`"$($this.PluginName)`""
        $step = "VerifyConditions"

        Add-ConsoleLog "Start step $step of plugin $typeName"

        $gitStatus = Get-GitStatus

        if ($gitStatus) {
            throw "[Git] Working tree is not clean. Commit or stash changes before releasing."
        }

        $assets = $this.Config.assets
        $message = $this.Config.message
        $hasAssets = $assets -is [array] -and $assets.Count -gt 0

        if (-not $hasAssets) {
            throw "[$($this.PluginName)] At least one asset needs to be specified."
        }

        if ($hasAssets -and -not $message) {
            throw "[$($this.PluginName)] A commit message needs to be specified."
        }

        if (-not $this.Context.DryRun) {
            Set-GitIdentity
        }

        $currentVersion = Get-CurrentSemanticVersion -context $this.Context.Config.Project.unifyTag
        $this.Context.CurrentVersion.Branch = $currentVersion

        if (-not $currentVersion) {
            Add-ConsoleLog "[$($this.PluginName)] No previous release found, retrieving all commits"
        }
        else {
            Add-ConsoleLog "[$($this.PluginName)] Found git tag v$currentVersion on branch $($this.Context.Repository.BranchCurrent)"
        }

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }

    [void] Prepare() {
        $typeName = "`"$($this.PluginName)`""
        $dryRun = $this.Context.DryRun
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
            Add-ConsoleLog "[$($this.PluginName)] Cannot find files listed in assets config"
        }
        else {
            Add-ConsoleLog "[$($this.PluginName)] Found $($lists.Count) file(s) to commit"

            # Stage files
            git add $lists 2>$null

            git restore .
            git restore --staged .

            git add $lists 2>$null

            $commitMessage = Expand-ContextString -context $this.Context -template $messageTemplate

            git commit -m $commitMessage --quiet
        }

        $version = $this.Context.NextRelease.Version

        $tag = "v$Version"

        if (Test-GitTagExist $tag) {
            throw "Tag $tag already exists"
        }

        if ($dryRun) {
            Add-ConsoleLog "[$($this.PluginName)] Skip $tag tag creation in DryRun mode"
        }
        else {
            git tag $tag 2>$null
        }

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }

    [void] Publish() {
        $typeName = "`"$($this.PluginName)`""
        $dryRun = $this.Context.DryRun
        $step = "Publish"

        if ($dryRun) { 
            Add-ConsoleLog "Skip step `"$step`" of plugin `"$typeName`" in DryRun mode"
            return
        }

        Add-ConsoleLog "Start step $step of plugin $typeName"
        
        $currentBranch = $this.Context.Repository.BranchCurrent
        $nextVersion = $this.Context.NextRelease.Version
        $assets = $this.Config.assets
        $message = $this.Config.message
        $hasAssets = $assets -is [array] -and $assets.Count -gt 0

        $tag = "v$nextVersion"
        $itemsToPush = $tag

        if ($message -and $hasAssets) {
            $itemsToPush = "$currentBranch $itemsToPush"
        }

        git push origin $itemsToPush 2>$null

        Add-ConsoleLog "[$($this.PluginName)] Prepared Git release: v${nextVersion}"

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }
}