function Get-SemanticReleaseConfig {
    param(
        [string]$Path = "semantic-release.json"
    )

    $Config = @{}

    if (Test-Path $Path) {
        $Config = Get-Content $Path -Raw | ConvertFrom-Json
    }

    $releaseRules = @()
    if ($null -eq $Config.releaseRules) {
        $releaseRules = @(
            @{ type = "fix"; release = "patch"; section = "Bug Fixes" },
            @{ type = "feat"; release = "minor"; section = "Features" }
        )
    }
    else {
        # only filter to get patch, minor entries
        $validRelease = @("patch", "minor")

        $validRules = $Config.releaseRules | Where-Object { $validRelease -contains $_.release }
        $releaseRules += @($validRules)
    }

    if (-not $Config.releaseRules) {
        $Config | Add-Member -NotePropertyName releaseRules -NotePropertyValue @()
    }

    $Config.releaseRules = $releaseRules

    return $Config
}
