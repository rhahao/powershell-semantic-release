function Invoke-SemanticRelease {
    param(
        [switch]$DryRun
    )

    try {
        # Confirm-GitClean

        # $context.NextRelease.Type = Get-ReleaseTypeFromCommits -context $context

        # if ($null -eq $context.NextRelease.Type) {
        #     return
        # }
        
        # $context.NextRelease.Version = Get-NextSemanticVersion -context $context

        # $context.NextRelease.Notes = New-ReleaseNotes -context $context        

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

        Update-PluginsList -context $context

        $plugins = Get-SemanticReleasePlugins -context $context

        $steps = @("VerifyConditions", "AnalyzeCommits", "VerifyRelease", "GenerateNotes", "Prepare", "Publish")

        # Loading step from plugins
        foreach ($step in $steps) {
            foreach ($plugin in $plugins) {
                $hasStep = Test-PluginStepExist -Plugin $plugin -Step $step

                if (-not $hasStep) { continue }
            
                Add-ConsoleLog "Loaded step $step of plugin $($plugin.GetType().Name)"
            }
        }    

        # $branchConfig = Confirm-ReleaseBranch
        # $context.Branch = $branchConfig.Branch
        # $context.NextRelease.Channel = $branchConfig.Channel

        Add-ConsoleLog "Running automated release from branch $($context.Branch) on repository $($context.Repository.RemoteUrl)"

        Confirm-EnvironmentCI

        $hasPushAccess = Test-GitPushAccessCI -context $context

        if (-not $hasPushAccess) { return }

        $context.CurrentVersion.Published = Get-CurrentSemanticVersion -context $context -Branch "main"
        $context.CurrentVersion.Branch = Get-CurrentSemanticVersion

        if (-not  $context.CurrentVersion.Branch) {
            Add-ConsoleLog "No previous release found, retrieving all commits"
        }
        else {
            Add-ConsoleLog "Found git tag v$($context.CurrentVersion.Branch) on branch $($context.Branch)"
        }

        $context.Commits.List = Get-ConventionalCommits -context $context
        $context.Commits.Formatted = if ($context.Commits.List.Count -eq 1) { "1 commit" } else { "$($context.Commits.List.Count) commits" }     

        if ($context.Commits.List.Count -eq 0) {
            Add-ConsoleLog "No commits found, no release needed"
            return
        }
        else {
            Add-ConsoleLog "Found $($context.Commits.Formatted) since last release"
        }

        # Doing step from plugins
        foreach ($plugin in $plugins) {
            $step = "AnalyzeCommits"
            
            $hasStep = Test-PluginStepExist -Plugin $plugin -Step $step

            if (-not $hasStep) { continue }

            $pluginName = $plugin.GetType().Name

            Add-ConsoleLog "Start step $step of plugin $pluginName"

            $plugin.$step()

            Add-ConsoleLog "Completed step $step of plugin $pluginName"
        }
    }
    catch {
        Write-Error $_
    }    
}
