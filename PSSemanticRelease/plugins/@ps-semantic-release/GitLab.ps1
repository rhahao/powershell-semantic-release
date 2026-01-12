class GitLab {
    [string]$PluginName
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    GitLab([string]$PluginName, [PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] TestReleasePermission() {
        try {
            $headers = @{
                "PRIVATE-TOKEN" = $($this.Config.token)
                "User-Agent"    = "PSSemanticRelease"
            }
    
            $project = Invoke-RestMethod `
                -Method Get `
                -Uri "$($this.Config.gitlabUrl)/api/v4/projects/$($this.Config.projectId)" `
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
        try {
            $itemObject = Get-Item -Path $path

            if ($itemObject.PSContainer) {
                $parent = $itemObject.Parent.FullName
                $destination = Join-Path $parent "$($itemObject.Name).zip"
                Compress-Archive -Path $path -DestinationPath $destination -Force | Out-Null

                $path = $destination
            }

            $headers = @{
                "PRIVATE-TOKEN" = $($this.Config.token)
                "User-Agent"    = "PSSemanticRelease"
            }

            $form = @{ 
                file = Get-Item -Path $path
            }
            
            $response = Invoke-RestMethod `
                -Method Post `
                -Uri "$($this.Config.gitlabUrl)/api/v4/projects/$($this.Config.projectId)/uploads" `
                -Headers $headers `
                -Form $form

                
            $fullPath = "$($this.Config.gitlabUrl)$($response.full_path)"

            Add-InformationLog -Message "Uploaded file: $fullPath" -Plugin $this.PluginName

            return [PSCustomObject]@{ Url = $fullPath; Alt = $response.alt }
        }
        catch {
            throw "Failed to upload asset $path to the project: $($_.Exception.Message)"
        }
    }

    [void] VerifyConditions() {
        try {
            $typeName = "`"$($this.PluginName)`""
            $step = "VerifyConditions"

            Add-InformationLog "Start step $step of plugin $typeName"
            
            $assets = $this.Config.assets

            if ($assets -and $assets -isnot [array]) {
                throw "[$($this.PluginName)] Specify the array of files to upload for a release."
            }

            if ($this.Context.CI) {
                if ($env:GITLAB_CI -eq "false") {
                    throw "[$($this.PluginName)] You are not running PSSemanticRelease using GitLab Pipeline"
                }

                if (-not $env:GITLAB_TOKEN -and -not $env:GL_TOKEN) {
                    throw "[$($this.PluginName)] No GitLab token (GITLAB_TOKEN or GL_TOKEN) found in CI environment."
                }
            }

            $token = $null

            if ($env:GITLAB_TOKEN) { $token = $env:GITLAB_TOKEN }
            if ($env:GL_TOKEN) { $token = $env:GL_TOKEN }

            $this.Config.token = $token

            $this.Config.gitlabUrl = if ($env:GITLAB_URL) {
                $env:GITLAB_URL.TrimEnd('/')
            }
            elseif ($env:GL_URL) {
                $env:GL_URL.TrimEnd('/')
            }
            else {
                "https://gitlab.com"
            }

            $repoUrl = $this.Context.Repository.Url
            $repo = $repoUrl.Substring($this.Config.gitlabUrl.Length).TrimStart('/')
            $this.Config.projectId = [uri]::EscapeDataString($repo)

            $message = Test-GitPushAccessCI -context $this.Context -token $token

            Add-SuccessLog -Message "$message to the GitLab repository" -Plugin $this.PluginName

            if ($this.Context.CI) {
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

        if ($dryRun) { 
            Add-WarningLog "Skip step `"$step`" of plugin $typename in DryRun mode"
            return
        }

        Add-InformationLog "Start step $step of plugin $typeName"

        $assets = $this.Config.assets
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

        $this.Config.validAssets = , $validAssets

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }

    [void] Publish() {
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

            if ($this.Config.validAssets.Count -gt 0) {
                foreach ($asset in $this.Config.validAssets) {
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
                "PRIVATE-TOKEN" = $($this.Config.token)
                "User-Agent"    = "PSSemanticRelease"
            }

            $response = Invoke-RestMethod `
                -Method Post `
                -Uri "$($this.Config.gitlabUrl)/api/v4/projects/$($this.Config.projectId)/releases" `
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