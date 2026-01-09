class CommitAnalyzer {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    CommitAnalyzer([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    $typeName = $this.GetType().Name

    [void] EnsureConfig() {
        if (-not $this.Config.releaseRules -or $this.Config.releaseRules -isnot [array] -or $this.Config.releaseRules.Count -eq 0) {
            $configDefault = $this.Context.Config.Default.plugins | Where-Object { $_.Name -eq $typeName }

            $this.Config = $configDefault.Config

            ($this.Context.Config.Project.plugins | Where-Object { $_.Name -eq $typeName }) | ForEach-Object {
                $_.Config = $configDefault.Config
            }
        }

        $releaseRules = @()
        $validRelease = @("patch", "minor")

        $validRules = $this.Config.releaseRules | Where-Object { $validRelease -contains $_.release }
        $releaseRules += @($validRules)

        $this.Config.releaseRules = $releaseRules
        ($this.Context.Config.Project.plugins | Where-Object { $_.Name -eq $typeName }) | ForEach-Object {
            $_.Config.ReleaseRules = $releaseRules
        }
    }

    [void] AnalyzeCommits() {
        $this.EnsureConfig()

        $types = @()

        foreach ($commit in $this.Context.Commits.List) {
            Add-ConsoleLog "[CommitAnalyzer] Analyzing commit: $($commit.Message)"

            $commitType = $this.Config.releaseRules | Where-Object { $_.type -eq $commit.Type }

            if ($null -eq $commitType) {
                Add-ConsoleLog "[CommitAnalyzer] The commit should not trigger a release"
            }
            else {
                if ($commit.Breaking -eq $true) {
                    Add-ConsoleLog "[CommitAnalyzer] The release type for the commit is major"
                    $types += "major"
                }
                else {
                    Add-ConsoleLog "[CommitAnalyzer] The release type for the commit is $($commitType.release)"
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

        Add-ConsoleLog "[CommitAnalyzer] Analysis of $($this.Context.Commits.Formatted) completed: $releaseType"

        $this.Context.NextRelease.Type = $type
    }
}