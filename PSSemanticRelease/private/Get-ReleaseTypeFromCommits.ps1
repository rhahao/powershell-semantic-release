function Get-ReleaseTypeFromCommits {
    param($context)

    $types = @()

    foreach ($commit in $context.Commits.List) {
        Add-ConsoleLog "Analyzing commit: $($commit.Message)"

        $commitType = $context.Config.releaseRules | Where-Object { $_.type -eq $commit.Type }

        if ($null -eq $commitType) {
            Add-ConsoleLog "The commit should not trigger a release"
        }
        else {
            if ($commit.Breaking -eq $true) {
                Add-ConsoleLog "The release type for the commit is major"
                $types += "major"
            }
            else {
                Add-ConsoleLog "The release type for the commit is $($commitType.release)"
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

    Add-ConsoleLog "Analysis of $($context.Commits.Formatted) completed: $releaseType"

    return $type
}
