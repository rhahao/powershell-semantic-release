class CommitAnalyzer {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    CommitAnalyzer([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] EnsureConfig() {
        if (-not $this.Config.releaseRules -or $this.Config.releaseRules -isnot [array] -or $this.Config.releaseRules.Count -eq 0) {
            $configDefault = $this.Context.ConfigDefault.plugins | Where-Object { $_.Name -eq "CommitAnalyzer" }

            $this.Config = $configDefault.Config

            ($this.Context.Config.plugins | Where-Object { $_.Name -eq "CommitAnalyzer" }) | ForEach-Object {
                $_.Config = $configDefault.Config
            }
        }

        $releaseRules = @()
        $validRelease = @("patch", "minor")

        $validRules = $this.Config.releaseRules | Where-Object { $validRelease -contains $_.release }
        $releaseRules += @($validRules)

        $this.Config.releaseRules = $releaseRules
        ($this.Context.Config.plugins | Where-Object { $_.Name -eq "CommitAnalyzer" }) | ForEach-Object {
            $_.Config.ReleaseRules = $configDefault.Config.ReleaseRules
        }
    }

    [void] AnalyzeCommits() {
        $this.EnsureConfig()
    }
}