function Write-Changelog {
    param(
        [string]$Version
    )

    $commits = Get-ConventionalCommits

    $lines = @(
        "## v$Version",
        ""
    )

    foreach ($group in $commits | Group-Object Type) {
        $lines += "### $($group.Name)"
        foreach ($c in $group.Group) {
            $lines += "- $($c.Subject)"
        }
        $lines += ""
    }

    $existing = if (Test-Path CHANGELOG.md) {
        Get-Content CHANGELOG.md -Raw
    }

    ($lines -join "`n") + "`n" + $existing | Set-Content CHANGELOG.md
}
