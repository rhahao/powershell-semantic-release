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
    }
}