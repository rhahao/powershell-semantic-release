class Changelog {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    Changelog([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] EnsureConfig() {
        $typeName = $this.GetType().Name
        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $typeName
        
        if (-not $this.Config.file) {
            $configDefault = $this.Context.Config.Default.plugins | Where-Object { $_.Name -eq $typeName }

            $this.Config = $configDefault.Config

            $this.Context.Config.Project.plugins[$pluginIndex].Config = $configDefault.Config
        }
    }

    [void] VerifyConditions() {
        try {
            [System.IO.Path]::GetFullPath($this.Config.file) | Out-Null
        }
        catch {
            throw "[Changelog] The file path of the Changelog plugin is invalid"
        }

        if ($this.Config.file -notlike "*.md") {
            throw "[Changelog] Only markdown (.md) file is supported for the changelog."
        }
    }
}