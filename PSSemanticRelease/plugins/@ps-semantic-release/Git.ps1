class Git {
    [string]$PluginName
    [PSCustomObject]$Context

    Git([string]$PluginName, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Context = $Context

        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $PluginName
        $this | Add-Member -NotePropertyName PluginIndex -NotePropertyValue $pluginIndex

        $this.EnsureConfig()
    }

    [void] EnsureConfig() {
        $typeName = $this.PluginName
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]
        
        if (-not $plugin.Config.message) {
            $configDefault = $this.Context.Config.Default.plugins | Where-Object { $_.Name -eq $typeName }

            $this.Context.Config.Project.plugins[$this.PluginIndex].Config.message = $configDefault.Config.message
        }

        if ($plugin.Config.assets) {
            $this.Context.Config.Project.plugins[$this.PluginIndex].Config.assets = , $plugin.Config.assets
        }
    }

    [void] VerifyConditions() {
        $typeName = "`"$($this.PluginName)`""
        $step = "VerifyConditions"
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        Add-InformationLog "Start step $step of plugin $typeName"

        $assets = $plugin.Config.assets
        $hasAssets = $assets -is [array]

        if ($hasAssets -and $assets.Count -gt 0) {
            throw "At least one asset needs to be specified in Git"
        }

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }

    [void] Prepare() {
        $typeName = "`"$($this.PluginName)`""
        $dryRun = $this.Context.DryRun
        $step = "Prepare"
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        if ($dryRun) { 
            Add-WarningLog "Skip step `"$step`" of plugin $typename in DryRun mode"
            return
        }

        Add-InformationLog "Start step $step of plugin $typeName"

        $assets = $plugin.Config.assets
        $messageTemplate = $plugin.Config.message
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

        if ($assets.Count -gt 0 -and $lists.Count -eq 0) { 
            Add-FailureLog -Message "Cannot find files listed in assets config" -Plugin $this.PluginName
        }
        else {
            if (-not $this.Context.DryRun) {
                Set-GitIdentity
            }
        
            Add-InformationLog -Message "Found $($lists.Count) file(s) to commit" -Plugin $this.PluginName

            # Stage files
            git add $lists 2>$null

            git restore .
            git restore --staged .

            git add $lists 2>$null

            git commit -m $commitMessage --quiet
        }

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }

    [void] Publish() {
        $typeName = "`"$($this.PluginName)`""
        $dryRun = $this.Context.DryRun
        $step = "Publish"
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        if ($dryRun) { 
            Add-WarningLog "Skip step `"$step`" of plugin $typename in DryRun mode"
            return
        }

        Add-InformationLog "Start step $step of plugin $typeName"
        
        $currentBranch = $this.Context.Repository.BranchCurrent
        $nextVersion = $this.Context.NextRelease.Version
        $assets = $plugin.Config.assets
        $message = $plugin.Config.message
        $hasAssets = $assets -is [array] -and $assets.Count -gt 0

        if ($message -and $hasAssets) {
            git push origin $currentBranch 2>$null

            Add-InformationLog -Message "Prepared Git release: v${nextVersion}" -Plugin $this.PluginName
        }        

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }
}