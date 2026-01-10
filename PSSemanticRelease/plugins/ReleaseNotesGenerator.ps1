class ReleaseNotesGenerator {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    ReleaseNotesGenerator([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context

        $this.EnsureConfig()
    }

    [void] EnsureConfig() {
        $typeName = $this.GetType().Name
        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $typeName
        
        if (-not $this.Config.commitsSort) {
            $configDefault = $this.Context.Config.Default.plugins | Where-Object { $_.Name -eq $typeName }

            $this.Config = $configDefault.Config

            $this.Context.Config.Project.plugins[$pluginIndex].Config = $configDefault.Config
        }
    }

    [void] GenerateNotes() {
        $typeName = $this.GetType().Name
        $step = "GenerateNotes"

        Add-ConsoleLog "Start step $step of plugin $typeName"

        $commits = $this.Context.Commits.List
        $dryRun = $this.Context.DryRun

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

        $repoUrl = $this.Context.Repository.Url
        $versionPrev = $this.Context.CurrentVersion.Branch
        $versionNext = $this.Context.NextRelease.Version
        $date = Get-Date -Format "yyyy-MM-dd"

        $compareUrl = Get-CompareUrl -RepositoryUrl $repoUrl -FromVersion $versionPrev -ToVersion $versionNext
        $title = ""

        if ($this.Context.NextRelease.Type -ne "major") {
            $title = "## "
        }
        else {
            $title = "# "
        }
    
        if ($compareUrl) {
            if ($dryRun) {
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

        $orderedSections = ($commitAnalyzerPlugin.Config.releaseRules | ForEach-Object { $_.section }) | Select-Object -Unique

        foreach ($section in $orderedSections) {
            if (-not $sections.Contains($section)) {
                continue
            }
             
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

                if ($dryRun) {
                    $line += "    "
                }

                $line += "* **$($commit.Scope):** $($commit.Subject)$commitLink"

                $lines += $line
            }

            $lines += ""
        }

        $notes = $lines -join "`n"

        $this.Context.NextRelease.Notes = $notes

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }
}