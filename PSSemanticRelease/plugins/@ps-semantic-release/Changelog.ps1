class Changelog {
    [string]$PluginName
    [PSCustomObject]$Context

    Changelog([string]$PluginName, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Context = $Context

        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $PluginName
        $this | Add-Member -NotePropertyName PluginIndex -NotePropertyValue $pluginIndex

        $this.EnsureConfig()
    }

    [void] EnsureConfig() {
        $typeName = $this.PluginName
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]
        
        if (-not $plugin.Config.file) {
            $configDefault = $this.Context.Config.Default.plugins | Where-Object { $_.Name -eq $typeName }

            $this.Context.Config.Project.plugins[$this.PluginIndex].Config = $configDefault.Config
        }
    }

    [void] VerifyConditions() {   
        $typeName = "`"$($this.PluginName)`""
        $step = "VerifyConditions"
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]
        $file = $plugin.Config.file

        Add-InformationLog "Start step $step of plugin $typeName"
           
        try {
            [System.IO.Path]::GetFullPath($file) | Out-Null
        }
        catch {
            throw "[$($this.PluginName)] The file path of the Changelog plugin is invalid"
        }

        if ($file -notlike "*.md") {
            throw "[$($this.PluginName)] Only markdown (.md) file is supported for the changelog."
        }

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }

    [void] Prepare() {
        $typeName = "`"$($this.PluginName)`""
        $dryRun = $this.Context.DryRun
        $step = "Prepare"
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]
        $changelogFile = $plugin.Config.file

        if ($dryRun) { 
            Add-WarningLog "Skip step `"$step`" of plugin $typename in DryRun mode"
            return
        }

        Add-InformationLog "Start step $step of plugin $typeName"

        $changelogTitle = $plugin.Config.title
        $notes = $this.Context.NextRelease.Notes        

        $preContents = ""
        $status = ""

        if (Test-Path $changelogFile) {
            $status = "Update $((Get-Item -Path $changelogFile).FullName)"

            $preContents = (Get-Content -Path $changelogFile -Raw -Encoding UTF8).Trim()
        }
        else {
            $status = "Create $((Get-Item -Path ".").FullName)/$changelogFile"
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

        Add-InformationLog -Message $status -Plugin $this.PluginName

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }
}