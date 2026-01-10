class GitHub {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    GitHub([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] VerifyConditions() {
        $typeName = $this.GetType().Name
        $step = "VerifyConditions"

        Add-ConsoleLog "Start step $step of plugin $typeName"
        
        $assets = $this.Config.assets

        if ($assets -and $assets -isnot [array]) {
            throw "[GitHub] Specify the array of files to upload for a release."
        }

        if ($this.Context.CI) {
            if ($env:GITHUB_ACTIONS -eq "false") {
                throw "[GitHub] You are not running PSSemanticRelease using GitHub Action"
            }

            if (-not $env:GITHUB_TOKEN -and -not $env:GH_TOKEN) {
                throw "[GitHub] No GitHub token (GITHUB_TOKEN or GH_TOKEN) found in CI environment."
            }
        }

        $token = $null

        if ($env:GITHUB_TOKEN) { $token = $env:GITHUB_TOKEN }
        if ($env:GH_TOKEN) { $token = $env:GH_TOKEN }

        Test-GitPushAccessCI -context $this.Context -token $token

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }

    [void] Publish() {
        $dryRun = $this.Context.DryRun
        $typeName = $this.GetType().Name
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

        Invoke-RestMethod `
            -Method Post `
            -Uri "https://api.github.com/repos/$repo/releases" `
            -Headers $headers `
            -Body $body `
            -ContentType "application/json" | Out-Null
    }
}