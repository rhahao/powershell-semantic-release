function Invoke-SemanticRelease {
    param(
        [switch]$DryRun
    )

    try {
        $confirmBranch = Confirm-ReleaseBranch

        if (-not $confirmBranch) { return }

        $semanticVersion = Get-PSSemanticReleaseVersion
        Write-Host "PSSemanticRelease version $semanticVersion"

        $remoteUrl = Get-GitRemoteUrl
        Write-Host "Running automated release from branch $confirmBranch on repository $remoteUrl"

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
        

        $latestVersion = Get-CurrentSemanticVersion

        if (-not $latestVersion) {
            Write-Host "No previous release found, retrieving all commits"
        }
        else {
            Write-Host "Found git tag v$latestVersion on branch $confirmBranch"
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
        $nextVersion = Get-NextSemanticVersion -Type $releaseType

        # $next = Get-NextSemanticVersion -CurrentVersion $CurrentVersion

        # if ($next -eq $CurrentVersion) {
        #     Write-Host "No release needed"
        #     return
        # }

        # Write-Host "Releasing v$next"

        # if (-not $DryRun) {
        #     New-Changelog -Version $next
        #     git add CHANGELOG.md
        #     git commit -m "chore(release): v$next"
        #     New-GitTag -Version $next
        # }
    }
    catch {
        Write-Error $_
    }    
}
