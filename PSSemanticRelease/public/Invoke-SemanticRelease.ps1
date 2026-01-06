function Invoke-SemanticRelease {
    param(
        [switch]$DryRun
    )

    try {
        $branchConfig = Confirm-ReleaseBranch

        if (-not $branchConfig) { return }

        $semanticVersion = Get-PSSemanticReleaseVersion
        Write-Host "PSSemanticRelease version $semanticVersion"

        $remoteUrl = Get-GitRemoteUrl
        $branch = $branchConfig.Branch
        Write-Host "Running automated release from branch $branch on repository $remoteUrl"

        if (-not (Test-GitPushAccessCI)) { return }

        Confirm-EnvironmentCI

        if ($DryRun) {
            Write-Host "Running in dry mode"
        }
        else {
            $IsCI = Test-CIEnvironment

            if (-not $IsCI) {
                Write-Host "Running in dry mode (not in CI environment)"
            }
        }       

        $latestVersion = Get-CurrentSemanticVersion -branch "main"
        $latestBranchVersion = Get-CurrentSemanticVersion

        if (-not $latestBranchVersion) {
            Write-Host "No previous release found, retrieving all commits"
        }
        else {
            Write-Host "Found git tag v$latestBranchVersion on branch $branch"
        }

        $commits = Get-ConventionalCommits

        if ($commits.Count -eq 0) {
            Write-Host "No commits found, no release needed"
            return
        }
        else {
            $commitsCount = if ($commits.Count -eq 1) { "1 commit" } else { "$($commits.Count) commits" }
            Write-Host "Found $commitsCount since last release"
        }

        $releaseType = Get-ReleaseTypeFromCommits -Commits $commits
        Get-NextSemanticVersion -Type $releaseType -BaseVersion $latestVersion -BranchVersion $latestBranchVersion -Channel $branchConfig.Channel
    }
    catch {
        Write-Error $_
    }    
}
