class GitHub {
    [string]$PluginName
    [PSCustomObject]$Context

    GitHub([string]$PluginName, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Context = $Context

        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $PluginName
        $this | Add-Member -NotePropertyName PluginIndex -NotePropertyValue $pluginIndex
    }

    [void] TestReleasePermission() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        $headers = @{
            Authorization = "Bearer $($plugin.Config.token)"
            Accept        = "application/vnd.github+json"
            "User-Agent"  = "PSSemanticRelease"
        }
    
        try {
            $body = @{
                tag_name = "prerelease-check"
                name     = "permission-check"
                draft    = $true
            } | ConvertTo-Json
    
            $response = Invoke-RestMethod `
                -Method Post `
                -Uri "$($plugin.Config.githubApiUrl)/repos/$($plugin.Config.repo)/releases" `
                -Headers $headers `
                -Body $body `
                -ContentType "application/json"

            $releaseId = $response.id

            Invoke-RestMethod `
                -Method Delete `
                -Uri "$($plugin.Config.githubApiUrl)/repos/$($plugin.Config.repo)/releases/$releaseId" `
                -Headers $headers
    
            Add-SuccessLog -Message "Allowed to create release to the GitHub repository" -Plugin $this.PluginName
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 422) {
                Add-SuccessLog -Message "Allowed to create release to the GitHub repository" -Plugin $this.PluginName
                return
            }
    
            throw $_
        }
    }

    [void] VerifyConditions() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        try {
            $typeName = "`"$($this.PluginName)`""
            $step = "VerifyConditions"

            Add-InformationLog "Start step $step of plugin $typeName"
            
            $assets = $plugin.Config.assets

            if ($assets -and $assets -isnot [array]) {
                throw "[$($this.PluginName)] Specify the array of files to upload for a release."
            }

            if ($this.Context.CI) {
                if ($env:GITHUB_ACTIONS -eq "false") {
                    throw "[$($this.PluginName)] You are not running PSSemanticRelease using GitHub Action"
                }

                if (-not $env:GITHUB_TOKEN -and -not $env:GH_TOKEN) {
                    throw "[$($this.PluginName)] No GitHub token (GITHUB_TOKEN or GH_TOKEN) found in CI environment."
                }
            }

            $plugin.Config.githubUrl = if ($env:GITHUB_SERVER_URL) {
                $env:GITHUB_SERVER_URL.TrimEnd('/')
            }
            elseif ($env:GITHUB_URL) {
                $env:GITHUB_URL.TrimEnd('/')
            }
            elseif ($env:GH_URL) {
                $env:GH_URL.TrimEnd('/')
            }
            else {
                "https://github.com"
            }
            
            $plugin.Config.githubApiUrl = if ($env:GITHUB_API_URL) {
                $env:GITHUB_API_URL.TrimEnd('/')
            }
            elseif ($env:GH_API_URL) {
                $env:GH_API_URL.TrimEnd('/')
            }
            else {
                "https://api.github.com"
            }

            $repoUrl = $this.Context.Repository.Url
            $plugin.Config.repo = $repoUrl.Substring($plugin.Config.githubUrl.Length).TrimStart('/')

            $plugin.Config.token = $this.Context.EnvCI.Token

            if ($this.Context.CI) {
                $this.TestReleasePermission()
            }

            Add-SuccessLog "Completed step $step of plugin $typeName"
        }
        catch {
            throw $_
        }
        
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
        
        $version = $this.Context.NextRelease.Version
        $tag = "v$($version)"

        $body = @{
            tag_name   = $tag
            name       = $tag
            body       = $this.Context.NextRelease.Notes
            prerelease = $this.Context.NextRelease.Prerelease
            draft      = $false
        } | ConvertTo-Json -Depth 5

        $headers = @{
            Authorization = "Bearer $($plugin.Config.token)"
            Accept        = "application/vnd.github+json"
            "User-Agent"  = "PSSemanticRelease"
        }

        $response = Invoke-RestMethod `
            -Method Post `
            -Uri "$($plugin.Config.githubApiUrl)/repos/$($plugin.Config.repo)/releases" `
            -Headers $headers `
            -Body $body `
            -ContentType "application/json"

        $releaseUrl = $response.html_url

        Add-InformationLog -Message "Published GitHub release: $releaseUrl" -Plugin $this.PluginName

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }
}