function Invoke-SemanticRelease {
    param(
        [switch]$DryRun
    )

    try {
        # Confirm-GitClean
        
        # if (-not $context.DryRun) {
        #     Set-GitIdentity

        #     Write-ChangeLog -context $context

        #     Push-GitAssets -context $context
        # }

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

        $steps = @("VerifyConditions", "AnalyzeCommits", "VerifyRelease", "GenerateNotes", "Prepare", "Publish")
        foreach ($step in $steps) {
            foreach ($plugin in $plugins) {
                $hasStep = Test-PluginStepExist -Plugin $plugin -Step $step

                if (-not $hasStep) { continue }
            
                Add-ConsoleLog "Loaded step $step of plugin $($plugin.GetType().Name)"
            }
        }

        Add-ConsoleLog "Running automated release from branch $($context.Repository.BranchCurrent) on repository $($context.Repository.RemoteUrl)"

        Confirm-EnvironmentCI

        Test-GitPushAccessCI -context $context

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

        Get-NextSemanticVersion -context $context

        $steps = @("VerifyRelease", "GenerateNotes", "Prepare", "Publish")
        foreach ($step in $steps) {
            foreach ($plugin in $plugins) {
                $hasStep = Test-PluginStepExist -Plugin $plugin -Step $step

                if (-not $hasStep) { continue }

                $pluginName = $plugin.GetType().Name

                Add-ConsoleLog "Start step $step of plugin $pluginName"

                $plugin.$step()

                Add-ConsoleLog "Completed step $step of plugin $pluginName"
            }
        }
    }
    catch {
        Write-Error $_
    }    
}
