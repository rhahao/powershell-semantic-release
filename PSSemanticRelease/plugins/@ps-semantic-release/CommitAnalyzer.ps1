class CommitAnalyzer {
    [string]$PluginName
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    CommitAnalyzer([string]$PluginName, [PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Config = $Config
        $this.Context = $Context

        $this.EnsureConfig()
    }

    [void] EnsureConfig() {
        $namePlugin = $this.PluginName
        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $namePlugin

        if (-not $this.Config.releaseRules -or $this.Config.releaseRules -isnot [array] -or $this.Config.releaseRules.Count -eq 0) {
            $configDefault = $this.Context.Config.Default.plugins | Where-Object { $_.Name -eq $namePlugin }

            $this.Config = $configDefault.Config

            $this.Context.Config.Project.plugins[$pluginIndex].Config = $configDefault.Config
        }

        $releaseRules = @()
        $validRelease = @("patch", "minor")

        $validRules = $this.Config.releaseRules | Where-Object { $validRelease -contains $_.release }
        $releaseRules += @($validRules)

        $this.Config.releaseRules = $releaseRules      

        $this.Context.Config.Project.plugins[$pluginIndex].Config.releaseRules = $releaseRules
    }

    [void] VerifyConditions() {
        $typeName = "`"$($this.PluginName)`""
        $step = "VerifyConditions"

        Add-ConsoleLog "Start step $step of plugin $typeName"

        $commitsList = Get-ConventionalCommits -context $this.Context
        $this.Context.Commits.List = $commitsList
        $this.Context.Commits.Formatted = if ($commitsList.Count -eq 1) { "1 commit" } else { "$($commitsList.Count) commits" }

        if ($commitsList.Count -eq 0) {
            Add-ConsoleLog "[$($this.PluginName)] No commits found, no release needed"

            $this.Context.Abort = $true
        }
        else {
            Add-ConsoleLog "[$($this.PluginName)] Found $($this.Context.Commits.Formatted) since last release"
        }

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }

    [void] AnalyzeCommits() {
        $typeName = "`"$($this.PluginName)`""
        $step = "AnalyzeCommits"

        Add-ConsoleLog "Start step $step of plugin $typeName"
        
        $types = @()

        foreach ($commit in $this.Context.Commits.List) {
            Add-ConsoleLog "[$($this.PluginName)] Analyzing commit: $($commit.Message)"

            $commitType = $this.Config.releaseRules | Where-Object { $_.type -eq $commit.Type }

            if ($null -eq $commitType) {
                Add-ConsoleLog "[$($this.PluginName)] The commit should not trigger a release"
            }
            else {
                if ($commit.Breaking -eq $true) {
                    Add-ConsoleLog "[$($this.PluginName)] The release type for the commit is major"
                    $types += "major"
                }
                else {
                    Add-ConsoleLog "[$($this.PluginName)] The release type for the commit is $($commitType.release)"
                    $types += $commitType.release
                }            
            }
        }

        $type = $types | Sort-Object -Unique

        if ($type -contains "major") {
            $type = $type | Where-Object { $_ -eq "major" }
        }

        if ($type -contains "minor") {
            $type = $type | Where-Object { $_ -eq "minor" }
        }

        if ($type -contains "patch") {
            $type = $type | Where-Object { $_ -eq "patch" }
        }

        $releaseType = if ($null -eq $type) { "no release needed" } else { "$type release" }

        Add-ConsoleLog "[$($this.PluginName)] Analysis of $($this.Context.Commits.Formatted) completed: $releaseType"

        $this.Context.NextRelease.Type = $type

        if ($null -eq $type) { 
            $this.Context.Abort = $true
        }
        else {
            $this.Context.NextRelease.Version = Get-NextSemanticVersion -context $this.Context
        }

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }
}