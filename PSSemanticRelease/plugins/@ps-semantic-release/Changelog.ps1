class Changelog {
    [string]$PluginName
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    Changelog([string]$PluginName, [PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Config = $Config
        $this.Context = $Context

        $this.EnsureConfig()
    }

    [void] EnsureConfig() {
        $typeName = $this.PluginName
        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $typeName
        
        if (-not $this.Config.file) {
            $configDefault = $this.Context.Config.Default.plugins | Where-Object { $_.Name -eq $typeName }

            $this.Config = $configDefault.Config

            $this.Context.Config.Project.plugins[$pluginIndex].Config = $configDefault.Config
        }
    }

    [void] VerifyConditions() {   
        $typeName = "`"$($this.PluginName)`""
        $step = "VerifyConditions"

        Add-InformationLog "Start step $step of plugin $typeName"
           
        try {
            [System.IO.Path]::GetFullPath($this.Config.file) | Out-Null
        }
        catch {
            throw "[$($this.PluginName)] The file path of the Changelog plugin is invalid"
        }

        if ($this.Config.file -notlike "*.md") {
            throw "[$($this.PluginName)] Only markdown (.md) file is supported for the changelog."
        }

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }

    [void] Prepare() {
        $typeName = "`"$($this.PluginName)`""
        $dryRun = $this.Context.DryRun
        $step = "Prepare"

        if ($dryRun) { 
            Add-WarningLog "Skip step `"$step`" of plugin `"$typeName`" in DryRun mode"
            return
        }

        Add-InformationLog "Start step $step of plugin $typeName"

        $changelogFile = $this.Config.file
        $changelogTitle = $this.Config.title
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