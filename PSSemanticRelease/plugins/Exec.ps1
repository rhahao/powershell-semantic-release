class Exec {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    Exec([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] VerifyConditions() {
        if (-not $this.Config.verifyConditionsPsScript) { return }

        $this.RunScript($this.Config.verifyConditionsPsScript)
    }

    [void] AnalyzeCommits() {
        if (-not $this.Config.analyzeCommitsPsScript) { return }

        $this.RunScript($this.Config.analyzeCommitsPsScript)
    }

    [void] VerifyRelease() {
        if (-not $this.Config.verifyReleasePsScript) { return }

        $this.RunScript($this.Config.verifyReleasePsScript)
    }

    [void] GenerateNotes() {
        if (-not $this.Config.generateNotesPsScript) { return }

        $this.RunScript($this.Config.generateNotesPsScript)
    }

    [void] Prepare() {
        if (-not $this.Config.preparePsScript) { return }

        $this.RunScript($this.Config.preparePsScript)
    }

    [void] Publish() {
        if (-not $this.Config.publishPsScript) { return }

        $this.RunScript($this.Config.publishPsScript)
    }

    [void] RunScript([string]$scriptProp) {
        if (-not $scriptProp) { return }

        # Split into tokens
        $tokens = $scriptProp -split " "

        # First token ending with .ps1 is the script file
        $file = $tokens | Where-Object { $_ -match '\.ps1$' } | Select-Object -First 1
        if (-not $file) {
            throw "[Exec] Could not find the file `"$scriptProp`""
        }

        # Everything else is arguments
        $arguments = $tokens | Where-Object { $_ -ne $file }

        # Replace placeholders from context
        $arguments = $arguments | ForEach-Object {
            Expand-ContextString -context $this.Context -template $_
        }

        # Resolve path
        if (-not (Test-Path $file)) {
            throw "[Exec] Script file `"$file`" not found."
        }

        # if ($this.Context.DryRun) {
        #     Add-ConsoleLog "[Exec] Would run script `"$file`" with arguments: $($arguments -join " ")"
        #     return
        # }

        Add-ConsoleLog "[Exec] Running `"$file`" with arguments: $($arguments -join ' ')"

        try {
            $processName = if ($global:PSVersionTable.PSVersion.Major -ge 7) { "pwsh" } else { "powershell" }
            $argsArray = @("-File", $file) + $arguments

            $process = Start-Process -FilePath $processName `
                -ArgumentList $argsArray `
                -NoNewWindow `
                -Wait `
                -PassThru

            if ($process.ExitCode -ne 0) {
                throw "[Exec] Script  `"$file`" failed with exit code $($process.ExitCode)"
            }
        }
        catch {
            throw "[Exec] failed executing `"$file`": $_"
        }
    }
}