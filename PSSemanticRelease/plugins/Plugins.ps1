class Plugins {
    [object]$plugins

    Plugins([object]$plugins) { 
        $this.plugins = $plugins 
    }

    [void] List() {
        $steps = @("VerifyConditions", "AnalyzeCommits", "VerifyRelease", "GenerateNotes", "Prepare", "Publish")
        foreach ($step in $steps) {
            foreach ($plugin in $this.plugins) {
                $hasStep = Test-PluginStepExist -Plugin $plugin -Step $step

                if (-not $hasStep) { continue }
            
                Add-SuccessLog "Loaded step $step of plugin `"$($plugin.PluginName)`""
            }
        }
    }

    [void] VerifyConditions() {
        foreach ($plugin in $this.plugins) {
            $hasStep = Test-PluginStepExist -Plugin $plugin -Step "VerifyConditions"

            if (-not $hasStep) { continue }
            
            $plugin.VerifyConditions()
        }
    }

    [string] AnalyzeCommits() {
        $types = @()

        foreach ($plugin in $this.plugins) {
            $hasStep = Test-PluginStepExist -Plugin $plugin -Step "AnalyzeCommits"

            if (-not $hasStep) { continue }
            
            $stepType = $plugin.AnalyzeCommits()

            if ($stepType) { $types += $stepType }
        }

        $type = Get-ReleaseTypeFromLists $types

        return $type
    }

    [void] VerifyRelease() {
        foreach ($plugin in $this.plugins) {
            $hasStep = Test-PluginStepExist -Plugin $plugin -Step "VerifyRelease"

            if (-not $hasStep) { continue }
            
            $plugin.VerifyRelease()
        }
    }

    [string] GenerateNotes() {
        $finalNotes = ""

        foreach ($plugin in $this.plugins) {
            $hasStep = Test-PluginStepExist -Plugin $plugin -Step "GenerateNotes"

            if (-not $hasStep) { continue }
            
            $notes = $plugin.GenerateNotes()            

            if ($null -eq $notes -or -not $notes.Trim()) { continue }

            if (-not $finalNotes) {
                $finalNotes = $notes
            }
            else {
                $finalNotes = "$finalNotes`n`n$notes"
            }
        }

        return $finalNotes
    }

    [void] Prepare() {
        foreach ($plugin in $this.plugins) {
            $hasStep = Test-PluginStepExist -Plugin $plugin -Step "Prepare"

            if (-not $hasStep) { continue }
            
            $plugin.Prepare()
        }
    }

    [void] Publish() {
        foreach ($plugin in $this.plugins) {
            $hasStep = Test-PluginStepExist -Plugin $plugin -Step "Publish"

            if (-not $hasStep) { continue }
            
            $plugin.Publish()
        }
    }
}