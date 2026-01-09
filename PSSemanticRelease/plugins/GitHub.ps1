class GitHub {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    GitHub([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] VerifyConditions() {
        $assets = $this.Config.assets

        if ($assets -and $assets -isnot [array]) {
            throw "[GitHub] Specify the array of files to upload for a release."
        }

        if ($this.Context.CI) {
            if ($env:GITHUB_ACTIONS -eq "false") {
                throw "[GitHub] You are not running PSSemanticRelease using GitHub Action"
            }

            if (-not $env:GITHUB_TOKEN -and -not $env:GH_TOKEN) {
                throw "[GitHub] No GitHub token (GITHUB_TOKEN or GH_TOKEN) found in CI environment."
            }
        }

        $token = $null

        if ($env:GITHUB_TOKEN) { $token = $env:GITHUB_TOKEN }
        if ($env:GH_TOKEN) { $token = $env:GH_TOKEN }

        Test-GitPushAccessCI -context $this.Context -token $token
    }
}