class Exec {
    [string]$PluginName
    [PSCustomObject]$Context

    Exec([string]$PluginName, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Context = $Context

        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $PluginName
        $this | Add-Member -NotePropertyName PluginIndex -NotePropertyValue $pluginIndex
    }

    [void] VerifyConditions() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        if (-not $plugin.Config.verifyConditionsPsScript) { return }

        $this.RunScript("VerifyConditions", $false, $plugin.Config.verifyConditionsPsScript)
    }

    [void] AnalyzeCommits() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        if (-not $plugin.Config.analyzeCommitsPsScript) { return }

        $this.RunScript("AnalyzeCommits", $false, $plugin.Config.analyzeCommitsPsScript)
    }

    [void] VerifyRelease() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        if (-not $plugin.Config.verifyReleasePsScript) { return }

        $this.RunScript("VerifyRelease", $false, $plugin.Config.verifyReleasePsScript)
    }

    [void] GenerateNotes() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        if (-not $plugin.Config.generateNotesPsScript) { return }

        $this.RunScript("GenerateNotes", $false, $plugin.Config.generateNotesPsScript)
    }

    [void] Prepare() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        if (-not $plugin.Config.preparePsScript) { return }

        $this.RunScript("Prepare", $false, $plugin.Config.preparePsScript)
    }

    [void] Publish() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]
        
        if (-not $plugin.Config.publishPsScript) { return }

        $this.RunScript("Publish", $true, $plugin.Config.publishPsScript)
    }

    [void] RunScript([string]$step, [bool]$haltDryRun, [string]$scriptProp) {
        if (-not $scriptProp) { return }

        $typeName = "`"$($this.PluginName)`""

        if ($haltDryRun -and $this.Context.DryRun) {
            Add-WarningLog "Skip step `"$step`" of plugin $typename in DryRun mode"
            return
        }

        Add-InformationLog "Start step $step of plugin $typeName"

        # Split into tokens
        $tokens = $scriptProp -split " "

        # First token ending with .ps1 is the script file
        $file = $tokens | Where-Object { $_ -match '\.ps1$' } | Select-Object -First 1
        if (-not $file) {
            throw "[$($this.PluginName)] Could not find the file `"$scriptProp`""
        }

        # Everything else is arguments
        $arguments = $tokens | Where-Object { $_ -ne $file }

        # Replace placeholders from context
        $arguments = $arguments | ForEach-Object {
            Expand-ContextString -context $this.Context -template $_
        }

        # Resolve path
        if (-not (Test-Path $file)) {
            throw "[$($this.PluginName)] Script file `"$file`" not found."
        }

        Add-InformationLog -Message "Running `"$file`" with arguments: $($arguments -join ' ')" -Plugin $this.PluginName

        try {
            $processName = if ($global:PSVersionTable.PSVersion.Major -ge 7) { "pwsh" } else { "powershell" }
            $argsArray = @("-File", $file) + $arguments

            $process = Start-Process -FilePath $processName -ArgumentList $argsArray -NoNewWindow -Wait -PassThru

            if ($process.ExitCode -ne 0) {
                throw "[$($this.PluginName)] Script  `"$file`" failed with exit code $($process.ExitCode)"
            }

            Add-SuccessLog "Completed step $step of plugin $typeName"
        }
        catch {
            throw "Exec failed executing `"$file`": $_"
        }
    }
}