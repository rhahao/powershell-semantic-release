function Invoke-SemanticRelease {
    param(
        [switch]$DryRun
    )

    try {
        $context = New-ReleaseContext

        $semanticVersion = Get-PSSemanticReleaseVersion
        & $context.Logger "PSSemanticRelease version $semanticVersion"

        $branchConfig = Confirm-ReleaseBranch
        $context.Branch = $branchConfig.Branch
        $context.NextRelease.Channel = $branchConfig.Channel
        $context.Repository = Get-GitRemoteUrl
    
        if (-not $context.Branch) { return }

        & $context.Logger "Running automated release from branch $($context.Branch) on repository $($context.Repository)"

        Confirm-EnvironmentCI

        if (-not (Test-GitPushAccessCI -context $context)) { return }        

        if ($DryRun) {
            & $context.Logger "Running in dry mode"
        }
        else {
            if (-not $context.IsCI) {
                & $context.Logger "Running in dry mode (not in CI environment)"
            }
        }

        $context.CurrentVersion.Published = Get-CurrentSemanticVersion -context $context -Branch "main"
        $context.CurrentVersion.Branch = Get-CurrentSemanticVersion

        if (-not  $context.CurrentVersion.Branch) {
            & $context.Logger "No previous release found, retrieving all commits"
        }
        else {
            & $context.Logger "Found git tag v$($context.CurrentVersion.Branch) on branch $($context.Branch)"
        }

        $context.Commits.List = Get-ConventionalCommits
        $context.Commits.Formatted = if ($context.Commits.List.Count -eq 1) { "1 commit" } else { "$($context.Commits.List.Count) commits" }

        if ($context.Commits.List.Count -eq 0) {
            & $context.Logger "No commits found, no release needed"
            return
        }
        else {
            & $context.Logger "Found $($context.Commits.Formatted) since last release"
        }

        $context.NextRelease.Type = Get-ReleaseTypeFromCommits -context $context
        $context.NextRelease.Version = Get-NextSemanticVersion -context $context

        Invoke-ReleaseScript -context $context
    }
    catch {
        Write-Error $_
    }    
}
