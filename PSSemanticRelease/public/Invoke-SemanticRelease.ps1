function Invoke-SemanticRelease {
    param(
        [switch]$DryRun
    )

    try {
        Confirm-GitClean
        
        $context = New-ReleaseContext $DryRun

        $semanticVersion = Get-PSSemanticReleaseVersion
        Add-ConsoleLog "PSSemanticRelease version $semanticVersion"

        $branchConfig = Confirm-ReleaseBranch
        $context.Branch = $branchConfig.Branch
        $context.NextRelease.Channel = $branchConfig.Channel
        $context.Repository.RemoteUrl = Get-GitRemoteUrl
        $context.Repository.Url = Resolve-RepositoryUrl $context.Repository.RemoteUrl
    
        if (-not $context.Branch) { return }

        Add-ConsoleLog "Running automated release from branch $($context.Branch) on repository $($context.Repository.RemoteUrl)"

        Confirm-EnvironmentCI

        if (-not (Test-GitPushAccessCI -context $context)) { return }

        if ($context.DryRun) {
            Add-ConsoleLog "Running in dry mode"
        }
        else {
            if (-not $context.CI) {
                $context.DryRun = $true
                Add-ConsoleLog "Running in dry mode (not in CI environment)"
            }
        }

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

        $context.NextRelease.Type = Get-ReleaseTypeFromCommits -context $context

        if ($null -eq $context.NextRelease.Type) {
            return
        }
        
        $context.NextRelease.Version = Get-NextSemanticVersion -context $context

        $context.DryRun = $false

        $context.NextRelease.Notes = New-ReleaseNotes -context $context

        if (-not $context.DryRun) {
            Write-ChangeLog -context $context

            Push-GitAssets -context $context
        }


        # Invoke-ReleaseScript -context $context
    }
    catch {
        Write-Error $_
    }    
}
