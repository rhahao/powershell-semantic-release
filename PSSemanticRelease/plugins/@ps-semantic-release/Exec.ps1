class Exec {
    [string]$PluginName
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    Exec([string]$PluginName, [PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] VerifyConditions() {
        if (-not $this.Config.verifyConditionsPsScript) { return }

        $this.RunScript("VerifyConditions", $false, $this.Config.verifyConditionsPsScript)
    }

    [void] AnalyzeCommits() {
        if (-not $this.Config.analyzeCommitsPsScript) { return }

        $this.RunScript("AnalyzeCommits", $false, $this.Config.analyzeCommitsPsScript)
    }

    [void] VerifyRelease() {
        if (-not $this.Config.verifyReleasePsScript) { return }

        $this.RunScript("VerifyRelease", $false, $this.Config.verifyReleasePsScript)
    }

    [void] GenerateNotes() {
        if (-not $this.Config.generateNotesPsScript) { return }

        $this.RunScript("GenerateNotes", $false, $this.Config.generateNotesPsScript)
    }

    [void] Prepare() {
        if (-not $this.Config.preparePsScript) { return }

        $this.RunScript("Prepare", $false, $this.Config.preparePsScript)
    }

    [void] Publish() {
        if (-not $this.Config.publishPsScript) { return }

        $this.RunScript("Publish", $true, $this.Config.publishPsScript)
    }

    [void] RunScript([string]$step, [bool]$haltDryRun, [string]$scriptProp) {
        if (-not $scriptProp) { return }

        $typeName = "`"$($this.PluginName)`""

        if ($haltDryRun -and $this.Context.DryRun) {
            Add-WarningLog "Skip step `"$step`" of plugin `"$typeName`" in DryRun mode"
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

        Add-ConsoleLog -Message "Running `"$file`" with arguments: $($arguments -join ' ')" -Plugin $this.PluginName

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