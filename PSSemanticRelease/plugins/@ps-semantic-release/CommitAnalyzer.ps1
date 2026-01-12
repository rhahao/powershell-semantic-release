class CommitAnalyzer {
    [string]$PluginName
    [PSCustomObject]$Context

    CommitAnalyzer([string]$PluginName, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Context = $Context

        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $PluginName
        $this | Add-Member -NotePropertyName PluginIndex -NotePropertyValue $pluginIndex

        $this.EnsureConfig()
    }

    [void] EnsureConfig() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        if (-not $plugin.Config.releaseRules -or $plugin.Config.releaseRules -isnot [array] -or $plugin.Config.releaseRules.Count -eq 0) {
            $configDefault = $this.Context.Config.Default.plugins | Where-Object { $_.Name -eq $this.PluginName }

            $this.Context.Config.Project.plugins[$this.PluginIndex].Config = $configDefault.Config
        }

        $releaseRules = @()
        $validRelease = @("patch", "minor")

        $validRules = $plugin.Config.releaseRules | Where-Object { $validRelease -contains $_.release }
        $releaseRules += @($validRules)

        $this.Context.Config.Project.plugins[$this.PluginIndex].Config.releaseRules = $releaseRules
    }

    [string] AnalyzeCommits() {
        $typeName = "`"$($this.PluginName)`""
        $step = "AnalyzeCommits"
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        Add-InformationLog "Start step $step of plugin $typeName"
        
        $types = @()

        foreach ($commit in $this.Context.Commits.List) {
            Add-InformationLog -Message "Analyzing commit: $($commit.Message)" -Plugin $this.PluginName

            $commitType = $plugin.Config.releaseRules | Where-Object { $_.type -eq $commit.Type }

            if ($null -eq $commitType) {
                Add-InformationLog -Message "The commit should not trigger a release" -Plugin $this.PluginName
            }
            else {
                if ($commit.Breaking -eq $true) {
                    Add-InformationLog -Message "The release type for the commit is major" -Plugin $this.PluginName
                    $types += "major"
                }
                else {
                    Add-InformationLog -Message "The release type for the commit is $($commitType.release)" -Plugin $this.PluginName
                    $types += $commitType.release
                }            
            }
        }

        $type = Get-ReleaseTypeFromLists $types

        $releaseType = if ($null -eq $type) { "no release needed" } else { "$type release" }

        Add-InformationLog -Message "Analysis of $($this.Context.Commits.Formatted) completed: $releaseType" -Plugin $this.PluginName

        Add-SuccessLog "Completed step $step of plugin $typeName"

        return $type
    }
}