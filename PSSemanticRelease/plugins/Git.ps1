class Git {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    Git([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] VerifyConditions() {
        $assets = $this.Config.assets
        $message = $this.Config.message

        if (-not $assets -or ($assets -is [array] -and $assets.Count -eq 0)) {
            throw "Git plugin requires at least one asset to be specified."
        }

        if (-not $message) {
            throw "Git plugin requires a commit message to be specified."
        }
    }
}