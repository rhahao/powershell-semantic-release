function Get-ReleaseTypeFromCommits {
    param(
        $Commits
    )

    $config = Get-SemanticReleaseConfig
    $rules = @()

    if ($null -eq $config.releaseRules) {
        $rules = @(
            @{ type = "fix"; release = "patch"; section = "Bug Fixes" },
            @{ type = "feat"; release = "minor"; section = "Features" }
        )
    }
    else {
        # only filter to get patch, minor entries
        $validRelease = @("patch", "minor")

        $validRules = $config.releaseRules | Where-Object { $validRelease -contains $_.release }
        $rules += @($validRules)
    }

    $types = @()

    foreach ($commit in $Commits) {
        Write-Host "Analyzing commit: $($commit.Message)"

        $commitType = $rules | Where-Object { $_.type -eq $commit.Type }

        if ($null -eq $commitType) {
            Write-Host "The commit should not trigger a release"
        }
        else {
            if ($commit.Breaking -eq $false) {
                Write-Host "The release type for the commit is major"
                $types += "major"
            }
            else {
                Write-Host "The release type for the commit is $($commitType.release)"
                $types += $commitType.release
            }            
        }
    }

    $type = $types | Sort-Object -Unique

    if ($type -contains "major") {
        $type = $type | Where-Object { $_ -eq "major" }
    }

    if ($type -contains "minor") {
        $type = $type | Where-Object { $_ -eq "minor" }
    }

    if ($type -contains "patch") {
        $type = $type | Where-Object { $_ -eq "patch" }
    }

    $commitsCount = if ($Commits.Count -eq 1) { "1 commit" } else { "$($Commits.Count) commits" }
    $releaseType = if ($null -eq $type) { "no release needed" } else { "$type release" }

    Write-Host "Analysis of $commitsCount complete: $releaseType"

    return $type
}
