class Git {
    [string]$PluginName
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    Git([string]$PluginName, [PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Config = $Config
        $this.Context = $Context

        $this.EnsureConfig()
    }

    [void] EnsureConfig() {
        $typeName = $this.PluginName
        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $typeName
        
        if (-not $this.Config.message) {
            $configDefault = $this.Context.Config.Default.plugins | Where-Object { $_.Name -eq $typeName }

            $this.Config.message = $configDefault.Config.message

            $this.Context.Config.Project.plugins[$pluginIndex].Config.message = $configDefault.Config.message
        }

        if ($this.Config.assets) {
            $this.Config.assets = , $this.Config.assets
        }
    }

    [void] VerifyConditions() {
        $typeName = "`"$($this.PluginName)`""
        $step = "VerifyConditions"

        Add-InformationLog "Start step $step of plugin $typeName"

        $gitStatus = Get-GitStatus

        if ($gitStatus) {
            throw "[$($this.PluginName)] Working tree is not clean. Commit or stash changes before releasing."
        }

        $assets = $this.Config.assets
        $hasAssets = $assets -is [array]

        if ($hasAssets -and $assets.Count -gt 0) {
            throw "[$($this.PluginName)] At least one asset needs to be specified."
        }

        if (-not $this.Context.DryRun) {
            Set-GitIdentity
        }

        $currentVersion = Get-CurrentSemanticVersion -context $this.Context.Config.Project.unifyTag
        $this.Context.CurrentVersion.Branch = $currentVersion

        if (-not $currentVersion) {
            Add-InformationLog -Message "No previous release found, retrieving all commits" -Plugin $this.PluginName
        }
        else {
            Add-InformationLog -Message "Found git tag v$currentVersion on branch $($this.Context.Repository.BranchCurrent)" -Plugin $this.PluginName
        }

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }

    [void] Prepare() {
        $typeName = "`"$($this.PluginName)`""
        $dryRun = $this.Context.DryRun
        $step = "Prepare"

        if ($dryRun) { 
            Add-WarningLog "Skip step `"$step`" of plugin $typename in DryRun mode"
            return
        }

        Add-InformationLog "Start step $step of plugin $typeName"

        $assets = $this.Config.assets
        $messageTemplate = $this.Config.message
        $commitMessage = Expand-ContextString -context $this.Context -template $messageTemplate

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
            Add-FailureLog -Message "Cannot find files listed in assets config" -Plugin $this.PluginName
        }
        else {
            Add-InformationLog -Message "Found $($lists.Count) file(s) to commit" -Plugin $this.PluginName

            # Stage files
            git add $lists 2>$null

            git restore .
            git restore --staged .

            git add $lists 2>$null

            git commit -m $commitMessage --quiet
        }

        $version = $this.Context.NextRelease.Version

        $tag = "v$Version"

        if (Test-GitTagExist $tag) {
            throw "Tag $tag already exists"
        }

        if ($dryRun) {
            Add-InformationLog -Message "Skip $tag tag creation in DryRun mode" -Plugin $this.PluginName
        }
        else {
            $commitMessageEscaped = $commitMessage -replace '^#', '\#'
            git tag -a $tag -m $commitMessageEscaped 2>$null
        }

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }

    [void] Publish() {
        $typeName = "`"$($this.PluginName)`""
        $dryRun = $this.Context.DryRun
        $step = "Publish"

        if ($dryRun) { 
            Add-WarningLog "Skip step `"$step`" of plugin $typename in DryRun mode"
            return
        }

        Add-InformationLog "Start step $step of plugin $typeName"
        
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

        Add-InformationLog -Message "Prepared Git release: v${nextVersion}" -Plugin $this.PluginName

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }
}