class NuGet {
    [string]$PluginName
    [PSCustomObject]$Context

    NuGet([string]$PluginName, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Context = $Context

        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $PluginName
        $this | Add-Member -NotePropertyName PluginIndex -NotePropertyValue $pluginIndex
    }

    [void] FormatReleaseNotes() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        $lines = $this.Context.NextRelease.Notes -split "`n"

        $final = @()

        foreach ($note in $lines) { 
            $line = $note
            # 1) Version header: "# [1.14.0](link) (date)" -> "1.14.0 (date)"
            if ($note -match '^(?:#{1,2})\s+\[([^\]]+)\]\([^)]+\)(.*)$') { 
                $version = $Matches[1]
                $suffix = $Matches[2]
                $line = "$version$suffix"
            }
            # 2) Section headings: "### Bug Fixes" -> "BUG FIXES"
            elseif ($note -match '^#{2,6}\s*(.+)$') {
                $scope = $Matches[1]
                $line = $scope.ToUpper()
            } # 3) Bullets: "* **plugins:** text ([hash](url))" -> " * plugins: text"
            elseif ($note -match '^\*\s') { 
                # remove bold markers
                $line = $note -replace '\*\*', ''
                # remove entire commit hash/link block: "([dc68eda](https://...))"
                $line = $line -replace '\(\[[^\]]+\]\(https?://[^)]+\)\)', ''
                # collapse multiple spaces
                $line = $line -replace '\s{2,}', ''
                # trim and indent $line = " $($line.Trim())" } $final.Add($line.TrimEnd()) }
            }

            $final += $line
        }

        $plugin.Config | Add-Member -NotePropertyName ReleaseNotes -NotePropertyValue ($final -join "`n")
    }

    [void] VerifyConditions() {
        $typeName = "`"$($this.PluginName)`""
        $step = "VerifyConditions"
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        Add-InformationLog "Start step $step of plugin $typeName"

        try {
            if (-not $this.Context.DryRun -and -not $env:NUGET_API_KEY) {
                throw "[$($this.PluginName)] No environment variable set for NUGET_API_KEY"
            }

            if (-not $plugin.Config.path) {
                throw "[$($this.PluginName)] Config `"path`" missing."
            }

            [System.IO.Path]::GetFullPath($plugin.Config.path) | Out-Null

            $Repository = $plugin.Repository
            $Source = $plugin.Source

            if ($Repository -and $Repository -ne "PSGallery" -and -not $Source) {
                throw "[$($this.PluginName)] Provide a valid source for $Repository"
            }

            if ($Repository -and $Repository -ne "PSGallery") {
                Register-PSRepository -Name $Repository -SourceLocation $Source -InstallationPolicy Trusted
            }

            Add-SuccessLog "Completed step $step of plugin $typeName"
        }
        catch {
            throw $_
        }
    }

    [void] Prepare() {    
        $typeName = "`"$($this.PluginName)`""
        $step = "Prepare"
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        Add-InformationLog "Start step $step of plugin $typeName"

        $path = Get-Item -Path "$($plugin.Config.path)/*.psd1" -ErrorAction SilentlyContinue 

        if ($null -eq $path) {
            throw "[$($this.PluginName)] Cannot find the module manifest in the provided $(this.Config.path)"
        }

        $this.FormatReleaseNotes()

        $Channel = $this.Context.NextRelease.Channel

        $params = @{
            ReleaseNotes = $plugin.ReleaseNotes
        }

        # Only add -Prerelease if supported
        if ($global:PSVersionTable.PSVersion.Major -ge 6 -and $Channel -ne "default") {
            $params.Prerelease = $Channel      
        }

        Update-ModuleManifest -Path $path @params

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }

    [void] Publish() {
        $typeName = "`"$($this.PluginName)`""
        $dryRun = $this.Context.DryRun
        $step = "Publish"
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        if ($dryRun) { 
            Add-WarningLog "Skip step `"$step`" of plugin $typename in DryRun mode"
            return
        }

        Add-InformationLog "Start step $step of plugin $typeName"

        try {
            $distPath = Get-Item -Path $plugin.Config.path
            $Repository = $plugin.Repository

            if (-not $Repository -or $Repository -eq "") {
                $Repository = "PSGallery"
            }

            Add-InformationLog -Message "Publishing module to $Repository" -Plugin $this.PluginName
            Publish-Module -Path $distPath -Repository $Repository -NuGetApiKey $env:NUGET_API_KEY
            Add-InformationLog -Message "Publish completed successfully" -Plugin $this.PluginName

            Add-SuccessLog "Completed step $step of plugin $typeName"
        }
        catch {
            throw $_
        }   
    }
}