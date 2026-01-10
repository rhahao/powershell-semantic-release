class Changelog {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    Changelog([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context

        $this.EnsureConfig()
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

    [void] VerifyConditions() {   
        $typeName = $this.GetType().Name
        $step = "VerifyConditions"

        Add-ConsoleLog "Start step $step of plugin $typeName"
           
        try {
            [System.IO.Path]::GetFullPath($this.Config.file) | Out-Null
        }
        catch {
            throw "[Changelog] The file path of the Changelog plugin is invalid"
        }

        if ($this.Config.file -notlike "*.md") {
            throw "[Changelog] Only markdown (.md) file is supported for the changelog."
        }

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }

    [void] Prepare() {
        $dryRun = $this.Context.DryRun
        $typeName = $this.GetType().Name
        $step = "Prepare"

        if ($dryRun) { 
            Add-ConsoleLog "Skip step `"$step`" of plugin `"$typeName`" in DryRun mode"
            return
        }

        Add-ConsoleLog "Start step $step of plugin $typeName"

        $changelogFile = $this.Config.file
        $changelogTitle = $this.Config.title
        $notes = $this.Context.NextRelease.Notes

        

        $preContents = ""
        $status = ""

        if (Test-Path $changelogFile) {
            $status = "[Changelog] Update $((Get-Item -Path $changelogFile).FullName)"

            $preContents = (Get-Content -Path $changelogFile -Raw -Encoding UTF8).Trim()
        }
        else {
            $status = "[Changelog] Create $((Get-Item -Path ".").FullName)/$changelogFile"
        }

        $currentContent = if ($changelogTitle -ne "" -and $preContents.StartsWith($changelogTitle)) {
            $preContents.Substring($changelogTitle.Length).Trim()
        }
        else {
            $preContents
        }

        $postContents = "$($notes.Trim())`n"

        $postContents += if ($null -ne $currentContent) { 
            "`n$($currentContent)`n" 
        }
        else { "" }

        $finalContents = if ($changelogTitle -ne "") {
            "$($changelogTitle)`n`n$($postContents)"
        }
        else {
            $postContents
        }

        Set-Content -Path $changelogFile -Value $finalContents -Encoding UTF8

        Add-ConsoleLog $status

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }
}