class Git {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    Git([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] VerifyConditions() {
        $assets = $this.Config.assets
        $message = $this.Config.message

        if (-not $assets -or ($assets -is [array] -and $assets.Count -eq 0)) {
            throw "[Git] At least one asset needs to be specified."
        }

        if (-not $message) {
            throw "[Git] A commit message needs to be specified."
        }
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
        $currentBranch = $this.Context.Repository.BranchCurrent

        git commit -m $commitMessage --quiet
        git push origin $currentBranch --quiet

        $nextVersion = $this.Context.NextRelease.Version

        Add-ConsoleLog "[Git] Prepared Git release: v${nextVersion}"

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }
}