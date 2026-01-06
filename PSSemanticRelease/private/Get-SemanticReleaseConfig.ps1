function Get-SemanticReleaseConfig {
    param(
        [string]$Path = "semantic-release.json"
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    Get-Content $Path -Raw | ConvertFrom-Json
}
