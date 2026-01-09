class Changelog {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    Changelog([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] EnsureConfig() {
        if (-not $this.Config.file) {
            $configDefault = $this.Context.ConfigDefault.plugins | Where-Object { $_.Name -eq "Changelog" }

            $this.Config = $configDefault.Config
            
            ($this.Context.Config.plugins | Where-Object { $_.Name -eq "Changelog" }) | ForEach-Object {
                $_.Config = $configDefault.Config
            }
        }
    }

    [void] VerifyConditions() {
        try {
            [System.IO.Path]::GetFullPath($this.Config.file) | Out-Null
        }
        catch {
            throw "The file path of the Changelog plugin is invalid"
        }

        if ($this.Config.file -notlike "*.md") {
            throw "Only markdown (.md) file is supported for the changelog."
        }
    }
}