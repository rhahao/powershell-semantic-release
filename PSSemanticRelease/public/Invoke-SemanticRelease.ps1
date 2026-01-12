function Invoke-SemanticRelease {
    param(
        [switch]$DryRun
    )

    try {
        Get-EnvFromFile

        $semanticVersion = Get-PSSemanticReleaseVersion
        Add-InformationLog "PSSemanticRelease version $semanticVersion"

        Test-GitRepository

        $context = New-ReleaseContext $DryRun

        if ($context.DryRun) {
            Add-InformationLog "Running in DryRun mode"
        }
        else {
            if (-not $context.CI) {
                $context.DryRun = $true
                Add-InformationLog "Running in DryRun mode (not in CI environment)"
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
            
                Add-SuccessLog "Loaded step $step of plugin `"$($plugin.PluginName)`""
            }
        }

        $logRan = "Running automated release from branch $($context.Repository.BranchCurrent) on repository $($context.Repository.RemoteUrl)"

        if ($context.DryRun) {
            $logRan += " in DryRun mode"
        }

        Add-SuccessLog $logRan

        # RUNNING PLUGINS STEPS
        $steps = @("VerifyConditions", "AnalyzeCommits", "VerifyRelease", "GenerateNotes", "Prepare", "Publish")
        foreach ($step in $steps) {
            foreach ($plugin in $plugins) {
                $hasStep = Test-PluginStepExist -Plugin $plugin -Step $step

                if (-not $hasStep) { continue }

                if ($context.Abort) {
                    $global:LASTEXITCODE = 0
                    return 
                }
            
                $plugin.$step()
            }            
        }

        # SHOW RELEASE NOTES FOR DRY RUN
        if ($context.DryRun) {    
            $versionNext = $context.NextRelease.Version        
            $notes = Format-ReleaseNotesDryRun $context.NextRelease.Notes
            Add-InformationLog "Release note for version ${versionNext}:`n$notes"
        }
    }
    catch {
        throw $_
    }    
}
