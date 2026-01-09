function Invoke-SemanticRelease {
    param(
        [switch]$DryRun
    )

    try {
        # Confirm-GitClean
        
        # New-GitTag -version $context.NextRelease.Version

        # Invoke-ReleaseScript -context $context

        # if (-not $context.DryRun) {
        #     Publish-Release -context $context
        # }

        $semanticVersion = Get-PSSemanticReleaseVersion
        Add-ConsoleLog "PSSemanticRelease version $semanticVersion"

        $context = New-ReleaseContext $DryRun

        if ($context.DryRun) {
            Add-ConsoleLog "Running in dry mode"
        }
        else {
            if (-not $context.CI) {
                $context.DryRun = $true
                Add-ConsoleLog "Running in dry mode (not in CI environment)"
            }
        }

        Confirm-ReleaseBranch -context $context

        Update-PluginsList -context $context

        $plugins = Get-SemanticReleasePlugins -context $context

        # LOADING PLUGINS & STEPS
        $steps = @("VerifyConditions", "AnalyzeCommits", "VerifyRelease", "GenerateNotes", "Prepare", "Publish")
        foreach ($step in $steps) {
            foreach ($plugin in $plugins) {
                $hasStep = Test-PluginStepExist -Plugin $plugin -Step $step

                if (-not $hasStep) { continue }
            
                Add-ConsoleLog "Loaded step $step of plugin $($plugin.GetType().Name)"
            }
        }

        $logRan = "Running automated release from branch $($context.Repository.BranchCurrent) on repository $($context.Repository.RemoteUrl)"

        if ($context.DryRun) {
            $logRan += " in DryRun mode"
        }

        Add-ConsoleLog $logRan

        # RUNNING VERIFYCONDITIONS STEP
        foreach ($plugin in $plugins) {
            $step = "VerifyConditions"
            
            $hasStep = Test-PluginStepExist -Plugin $plugin -Step $step

            if (-not $hasStep) { continue }

            $pluginName = $plugin.GetType().Name

            Add-ConsoleLog "Start step $step of plugin $pluginName"

            $plugin.$step()

            Add-ConsoleLog "Completed step $step of plugin $pluginName"
        }

        $context.CurrentVersion.Published = Get-CurrentSemanticVersion -context $context -Branch $context.Repository.BranchDefault
        $context.CurrentVersion.Branch = Get-CurrentSemanticVersion -context $context

        if (-not  $context.CurrentVersion.Branch) {
            Add-ConsoleLog "No previous release found, retrieving all commits"
        }
        else {
            Add-ConsoleLog "Found git tag v$($context.CurrentVersion.Branch) on branch $($context.Repository.BranchCurrent)"
        }        
        
        $commitsList = Get-ConventionalCommits -context $context
        $context.Commits.List = $commitsList
        $context.Commits.Formatted = if ($commitsList.Count -eq 1) { "1 commit" } else { "$($commitsList.Count) commits" }

        if ($commitsList.Count -eq 0) {
            Add-ConsoleLog "No commits found, no release needed"
            return
        }
        else {
            Add-ConsoleLog "Found $($context.Commits.Formatted) since last release"
        }

        # RUNNING ANALYZECOMMITS STEP
        foreach ($plugin in $plugins) {
            $step = "AnalyzeCommits"
            
            $hasStep = Test-PluginStepExist -Plugin $plugin -Step $step

            if (-not $hasStep) { continue }

            $pluginName = $plugin.GetType().Name

            Add-ConsoleLog "Start step $step of plugin $pluginName"

            $plugin.$step()

            Add-ConsoleLog "Completed step $step of plugin $pluginName"
        }

        if ($null -eq $context.NextRelease.Type) { return }

        if (-not $context.DryRun) {
            Set-GitIdentity
        }

        Get-NextSemanticVersion -context $context

        # RUNNING FEW STEPS
        $steps = @("VerifyRelease", "GenerateNotes", "Prepare")
        foreach ($step in $steps) {
            foreach ($plugin in $plugins) {
                $hasStep = Test-PluginStepExist -Plugin $plugin -Step $step

                if (-not $hasStep) { continue }

                $pluginName = $plugin.GetType().Name
                $plugin.$step()
            }
        }

        # TAG CREATION
        New-GitTag -context $context

        # RUNNING FINAL STEPS
        $steps = @("Publish")
        foreach ($step in $steps) {
            foreach ($plugin in $plugins) {
                $hasStep = Test-PluginStepExist -Plugin $plugin -Step $step

                if (-not $hasStep) { continue }

                $pluginName = $plugin.GetType().Name
                $plugin.$step()
            }
        }

        # SHOW RELEASE NOTES FOR DRY RUN
        if ($context.DryRun) {    
            $versionNext = $context.NextRelease.Version        
            $notes = $context.NextRelease.Notes

            Add-ConsoleLog "Release note for version ${versionNext}:`n$notes"
        }
    }
    catch {
        throw $_
    }    
}
