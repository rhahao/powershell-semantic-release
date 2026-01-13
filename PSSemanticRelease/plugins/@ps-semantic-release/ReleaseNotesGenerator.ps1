class ReleaseNotesGenerator {
    [string]$PluginName
    [PSCustomObject]$Context

    ReleaseNotesGenerator([string]$PluginName, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Context = $Context

        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $PluginName
        $this | Add-Member -NotePropertyName PluginIndex -NotePropertyValue $pluginIndex

        $this.EnsureConfig()
    }

    [void] EnsureConfig() {
        $typeName = $this.PluginName
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]
        
        if (-not $plugin.commitsSort) {
            $configDefault = $this.Context.Config.Default.plugins | Where-Object { $_.Name -eq $typeName }

            $plugin = $configDefault.Config
        }
    }

    [string] GenerateNotes() {
        $typeName = "`"$($this.PluginName)`""
        $step = "GenerateNotes"
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        Add-InformationLog "Start step $step of plugin $typeName"

        $commits = $this.Context.Commits.List

        $releaseRules = [hashtable]@{}

        $commitAnalyzerPluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name "@ps-semantic-release/CommitAnalyzer"
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

        $notes = ""

        if ($sections.Count -eq 0) {
            Add-InformationLog -Message "No user facing changes" -Plugin $this.PluginName
        }
        else {
            $lines = @()

            $repoUrl = $this.Context.Repository.Url
            $versionPrev = $this.Context.CurrentVersion.Branch
            $versionNext = $this.Context.NextRelease.Version
            $date = Get-Date -Format "yyyy-MM-dd"

            $compareUrl = Get-CompareUrl -RepositoryUrl $repoUrl -FromVersion $versionPrev -ToVersion $versionNext
            $title = ""

            if ($this.Context.NextRelease.Type -eq "patch") {
                $title = "## "
            }
            else {
                $title = "# "
            }
    
            if ($compareUrl) {
                $title += "[$versionNext]($compareUrl) "
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
                $sectionSortKeys = $plugin.commitsSort
            
                $sortedCommits = Format-SortCommits -Commits $sectionCommits -SortKeys $sectionSortKeys

                foreach ($commit in $sortedCommits) {
                    $commitLink = ""

                    $link = Get-CommitUrl -RepositoryUrl $repoUrl -Sha $commit.Sha

                    if ($link) {
                        $shortSha = $commit.Sha.Substring(0, 7)
                        $commitLink = " ([$shortSha]($link))"
                    }

                    $line = "* **$($commit.Scope):** $($commit.Subject)$commitLink"

                    $lines += $line
                }

                $lines += ""
            }

            $notes = $lines -join "`n"
        }    
            
        Add-SuccessLog "Completed step $step of plugin $typeName"

        return $notes
    }
}