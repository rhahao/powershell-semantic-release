class Git {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    $typeName = $this.GetType().Name

    Git([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] VerifyConditions() {
        $assets = $this.Config.assets
        $message = $this.Config.message

        if (-not $assets -or ($assets -is [array] -and $assets.Count -eq 0)) {
            throw "[Git] At least one asset needs to be specified."
        }

        if (-not $message) {
            throw "[Git] A commit message needs to be specified."
        }
    }
}