class GitLab {
    [string]$PluginName
    [PSCustomObject]$Context

    GitLab([string]$PluginName, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Context = $Context

        $pluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $PluginName
        $this | Add-Member -NotePropertyName PluginIndex -NotePropertyValue $pluginIndex
    }

    [void] TestReleasePermission() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        try {
            $headers = @{
                "PRIVATE-TOKEN" = $($plugin.Config.token)
                "User-Agent"    = "PSSemanticRelease"
            }
    
            $project = Invoke-RestMethod `
                -Method Get `
                -Uri "$($plugin.Config.gitlabUrl)/api/v4/projects/$($plugin.Config.projectId)" `
                -Headers $headers

            $access = $project.permissions.project_access.access_level

            if ($access -ge 30) {
                Add-SuccessLog -Message "Allowed to create release to the GitLab repository" -Plugin $this.PluginName
                return
            }

            throw "[$($this.PluginName)]  Token does not have sufficient permissions to create GitLab releases."
        }
        catch {
            throw "[$($this.PluginName)] Cannot access project or lacks permission: $($_.Exception.Message)"
        }
    }

    [PSCustomObject] UploadFileToProject([string]$path) {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        try {
            $itemObject = Get-Item -Path $path

            if ($itemObject.PSContainer) {
                $parent = $itemObject.Parent.FullName
                $destination = Join-Path $parent "$($itemObject.Name).zip"
                Compress-Archive -Path $path -DestinationPath $destination -Force | Out-Null

                $path = $destination
            }

            $headers = @{
                "PRIVATE-TOKEN" = $($plugin.Config.token)
                "User-Agent"    = "PSSemanticRelease"
            }

            $form = @{ 
                file = Get-Item -Path $path
            }
            
            $response = Invoke-RestMethod `
                -Method Post `
                -Uri "$($plugin.Config.gitlabUrl)/api/v4/projects/$($plugin.Config.projectId)/uploads" `
                -Headers $headers `
                -Form $form

                
            $fullPath = "$($plugin.Config.gitlabUrl)$($response.full_path)"

            Add-InformationLog -Message "Uploaded file: $fullPath" -Plugin $this.PluginName

            return [PSCustomObject]@{ Url = $fullPath; Alt = $response.alt }
        }
        catch {
            throw "Failed to upload asset $path to the project: $($_.Exception.Message)"
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

            if ($this.Context.EnvCI.IsCI) {
                if ($env:GITLAB_CI -eq "false") {
                    throw "[$($this.PluginName)] You are not running PSSemanticRelease using GitLab Pipeline"
                }

                if (-not $env:GITLAB_TOKEN -and -not $env:GL_TOKEN) {
                    throw "[$($this.PluginName)] No GitLab token (GITLAB_TOKEN or GL_TOKEN) found in CI environment."
                }
            }

            $plugin.Config.token = $this.Context.EnvCI.Token

            $plugin.Config.gitlabUrl = if ($env:GITLAB_URL) {
                $env:GITLAB_URL.TrimEnd('/')
            }
            elseif ($env:GL_URL) {
                $env:GL_URL.TrimEnd('/')
            }
            else {
                "https://gitlab.com"
            }

            $repoUrl = $this.Context.Repository.Url
            $repo = $repoUrl.Substring($plugin.Config.gitlabUrl.Length).TrimStart('/')
            $plugin.Config.projectId = [uri]::EscapeDataString($repo)

            if ($this.Context.EnvCI.IsCI) {
                $this.TestReleasePermission()
            }

            Add-SuccessLog "Completed step $step of plugin $typeName"
        }
        catch {
            throw $_
        }
    }

    [void] Prepare() {
        $typeName = "`"$($this.PluginName)`""
        $dryRun = $this.Context.DryRun
        $step = "Prepare"
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        if ($dryRun) { 
            Add-WarningLog "Skip step `"$step`" of plugin $typename in DryRun mode"
            return
        }

        Add-InformationLog "Start step $step of plugin $typeName"

        $assets = $plugin.Config.assets
        $validAssets = @()

        if ($assets -and $assets -is [array]) {
            foreach ($asset in $assets) {
                if ($asset.path -and (Test-Path $asset.path)) {
                    $validAssets += $asset
                }

                if ($asset.url) {
                    $validAssets += $asset
                }
            }
        }

        $plugin.Config.validAssets = , $validAssets

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }

    [void] Publish() {
        $plugin = $this.Context.Config.Project.plugins[$this.PluginIndex]

        try {
            $typeName = "`"$($this.PluginName)`""
            $dryRun = $this.Context.DryRun
            $step = "Publish"

            if ($dryRun) { 
                Add-WarningLog "Skip step `"$step`" of plugin $typename in DryRun mode"
                return
            }

            Add-InformationLog "Start step $step of plugin $typeName"

            $assetsLinks = @()

            if ($plugin.Config.validAssets.Count -gt 0) {
                foreach ($asset in $plugin.Config.validAssets) {
                    if ($asset.url) {
                        $assetsLinks += @{ name = $asset.label; url = $asset.url; link_type = "other" }
                    }

                    if ($asset.path) {
                        $response = UploadFileToProject $asset.path

                        $name = if (-not $asset.label) { $response.Alt } else { $asset.label }

                        $assetsLinks += @{ name = $name; url = $response.Url; link_type = "other" }
                    }
                }
            }            
        
            $version = $this.Context.NextRelease.Version
            $tag = "v$($version)"

            $body = @{
                name        = $tag
                tag_name    = $tag
                description = $this.Context.NextRelease.Notes
            }

            if ($assetsLinks.Count -gt 0) { 
                $body.assets = @{ links = $assetsLinks }
            }

            $bodyJson = $body | ConvertTo-Json -Depth 5

            $headers = @{
                "PRIVATE-TOKEN" = $($plugin.Config.token)
                "User-Agent"    = "PSSemanticRelease"
            }

            $response = Invoke-RestMethod `
                -Method Post `
                -Uri "$($plugin.Config.gitlabUrl)/api/v4/projects/$($plugin.Config.projectId)/releases" `
                -Headers $headers `
                -Body $bodyJson `
                -ContentType "application/json"

            $releaseUrl = $response.web_url

            Add-InformationLog -Message "Published GitLab release: $releaseUrl" -Plugin $this.PluginName

            Add-SuccessLog "Completed step $step of plugin $typeName"
        }
        catch {
            throw $_
        }
    }
}