class GitHub {
    [string]$PluginName
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    GitHub([string]$PluginName, [PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] VerifyConditions() {
        $typeName = "`"$($this.PluginName)`""
        $step = "VerifyConditions"

        Add-ConsoleLog "Start step $step of plugin $typeName"
        
        $assets = $this.Config.assets

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

        $token = $null

        if ($env:GITHUB_TOKEN) { $token = $env:GITHUB_TOKEN }
        if ($env:GH_TOKEN) { $token = $env:GH_TOKEN }

        Test-GitPushAccessCI -context $this.Context -token $token

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }

    [void] Publish() {
        $typeName = "`"$($this.PluginName)`""
        $dryRun = $this.Context.DryRun
        $step = "Publish"

        if ($dryRun) { 
            Add-ConsoleLog "Skip step `"$step`" of plugin `"$typeName`" in DryRun mode"
            return
        }
        
        $repoUrl = $this.Context.Repository.Url
        $version = $this.Context.NextRelease.Version

        $repo = $repoUrl -replace '^https://github.com/', ''
        $tag = "v$($version)"

        $body = @{
            tag_name   = $tag
            name       = $tag
            body       = $this.Context.NextRelease.Notes
            prerelease = [bool]$this.Context.NextRelease.Channel
            draft      = $false
        } | ConvertTo-Json -Depth 5

        $token = if ($env:GH_TOKEN) { $env:GH_TOKEN } else { $env:GITHUB_TOKEN }

        $headers = @{
            Authorization = "Bearer $token"
            Accept        = "application/vnd.github+json"
            "User-Agent"  = "PSSemanticRelease"
        }

        $response = Invoke-RestMethod `
            -Method Post `
            -Uri "https://api.github.com/repos/$repo/releases" `
            -Headers $headers `
            -Body $body `
            -ContentType "application/json"

        $releaseUrl = $response.html_url

        Add-ConsoleLog "[$($this.PluginName)] Published GitHub release: $releaseUrl"
    }
}