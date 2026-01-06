function Get-ReleaseTypeFromCommits {
    param($context)

    $rules = @()

    if ($null -eq $context.Config.releaseRules) {
        $rules = @(
            @{ type = "fix"; release = "patch"; section = "Bug Fixes" },
            @{ type = "feat"; release = "minor"; section = "Features" }
        )
    }
    else {
        # only filter to get patch, minor entries
        $validRelease = @("patch", "minor")

        $validRules = $context.Config.releaseRules | Where-Object { $validRelease -contains $_.release }
        $rules += @($validRules)
    }

    $types = @()

    foreach ($commit in $context.Commits.List) {
        & $context.Logger "Analyzing commit: $($commit.Message)"

        $commitType = $rules | Where-Object { $_.type -eq $commit.Type }

        if ($null -eq $commitType) {
            & $context.Logger "The commit should not trigger a release"
        }
        else {
            if ($commit.Breaking -eq $true) {
                & $context.Logger "The release type for the commit is major"
                $types += "major"
            }
            else {
                & $context.Logger "The release type for the commit is $($commitType.release)"
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

    $releaseType = if ($null -eq $type) { "no release needed" } else { "$type release" }

    & $context.Logger "Analysis of $($context.Commits.Formatted) completed: $releaseType"

    return $type
}
