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
            throw "[Git] At least one asset needs to be specified."
        }

        if (-not $message) {
            throw "[Git] A commit message needs to be specified."
        }
    }

    [void] Prepare() {
        $dryRun = $this.Context.DryRun
        $typeName = $this.GetType().Name
        $step = "Prepare"

        if ($dryRun) { 
            Add-ConsoleLog "Skip step `"$step`" of plugin `"$typeName`" in DryRun mode"
            return
        }

        Add-ConsoleLog "Start step $step of plugin $typeName"

        

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }
}