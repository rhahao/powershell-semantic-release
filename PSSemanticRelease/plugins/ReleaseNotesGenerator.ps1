class ReleaseNotesGenerator {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    ReleaseNotesGenerator([PSCustomObject]$Config, [PSCustomObject]$Context) {
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

    [void] GenerateNotes() {
        $this.EnsureConfig()

        $commits = $this.Context.Commits.List
        $releaseRules = [hashtable]@{}

        $commitAnalyzerPluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name "CommitAnalyzer"
        $commitAnalyzerPlugin = $this.Context.Config.Project.plugins[$commitAnalyzerPluginIndex]

        foreach ($rule in $commitAnalyzerPlugin.Config.releaseRules) {
            $releaseRules[$rule.type] = @{
                Release = $rule.release
                Section = $rule.section
            }
        }

        $sections = [ordered]@{}

        foreach ($commit in $commits) {
            if (-not $releaseRules.ContainsKey($commit.Type)) {
                continue
            }

            $rule = $releaseRules[$commit.Type]
            $section = $rule.Section

            if (-not $sections.Contains($section)) {
                $sections[$section] = @()
            }

            $sections[$section] += $commit
        }

        if ($sections.Count -eq 0) {
            Add-ConsoleLog "No user facing changes"
            return
        }

        $lines = @()

        $repoUrl = $this.Context.Config.Repository.Url
        $versionPrev = $this.Context.Config.CurrentVersion.Branch
        $versionNext = $this.Context.Config.NextRelease.Version
        $date = Get-Date -Format "yyyy-MM-dd"

        $compareUrl = Get-CompareUrl -RepositoryUrl $repoUrl -FromVersion $versionPrev -ToVersion $versionNext
        $title = ""

        if ($this.Context.Config.NextRelease.Type -eq "patch") {
            $title = "## "
        }
        else {
            $title = "# "
        }
    
        if ($compareUrl) {
            if ($this.Context.Config.DryRun) {
                $title += "$versionNext ($compareUrl) "
            }
            else {

                $title += "[$versionNext]($compareUrl) "
            }
        }
        else {
            $title += "$versionNext "
        }

        $title += "($date)"

        $lines += $title
        $lines += ""

        foreach ($section in $sections.Keys) {
            $lines += "### $section"
            $lines += ""

            $sectionCommits = $sections[$section]
            $sectionSortKeys = $this.Config.commitsSort
            $sortedCommits = Format-SortCommits -Commits $sectionCommits -SortKeys $sectionSortKeys

            foreach ($commit in $sortedCommits) {
                $commitLink = ""

                $link = Get-CommitUrl -RepositoryUrl $repoUrl -Sha $commit.Sha

                if ($link) {
                    $shortSha = $commit.Sha.Substring(0, 7)
                    $commitLink = " ([$shortSha]($link))"
                }

                $line = ""

                if ($this.Context.Config.DryRun) {
                    $line += "    "
                }

                $line += "* **$($commit.Scope):** $($commit.Subject)$commitLink"

                $lines += $line
            }

            $lines += ""
        }

        $notes = $lines -join "`n"

        if ($this.Context.Config.DryRun) {
            Add-ConsoleLog "Release note for version ${versionNext}:`n$notes"
        }

        $this.Context.NextRelease.Notes = $notes
    }
}