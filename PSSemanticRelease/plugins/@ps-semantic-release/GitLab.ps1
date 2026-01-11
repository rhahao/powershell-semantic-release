class GitLab {
    [string]$PluginName
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    GitLab([string]$PluginName, [PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Config = $Config
        $this.Context = $Context
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

            $message = Test-GitPushAccessCI -context $this.Context -token $token

            Add-SuccessLog -Message "$message to the GitLab repository" -Plugin $this.PluginName

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

        if ($dryRun) { 
            Add-WarningLog "Skip step `"$step`" of plugin $typename in DryRun mode"
            return
        }

        Add-InformationLog "Start step $step of plugin $typeName"
        
        $repoUrl = $this.Context.Repository.Url
        $version = $this.Context.NextRelease.Version

        $gitlabUrl = if ($env:GITLAB_URL) {
            $env:GITLAB_URL.TrimEnd('/')
        }
        elseif ($env:GL_URL) {
            $env:GL_URL.TrimEnd('/')
        }
        else {
            "https://gitlab.com"
        }

        $repo = $repoUrl.Substring($gitlabUrl.Length).TrimStart('/')
        $projectId = [uri]::EscapeDataString($repo)

        $tag = "v$($version)"

        $body = @{
            name        = $tag
            tag_name    = $tag
            description = $this.Context.NextRelease.Notes
        } | ConvertTo-Json -Depth 5

        $token = if ($env:GL_TOKEN) { $env:GL_TOKEN } else { $env:GITLAB_TOKEN }

        $headers = @{
            "PRIVATE-TOKEN" = $token
            "User-Agent"  = "PSSemanticRelease"
        }        

        $response = Invoke-RestMethod `
            -Method Post `
            -Uri "$gitlabUrl/api/v4/projects/$projectId/releases"
            -Headers $headers `
            -Body $body `
            -ContentType "application/json"

        $releaseUrl = $response.web_url

        Add-InformationLog -Message "Published GitLab release: $releaseUrl" -Plugin $this.PluginName

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }
}