class GitLab {
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    GitLab([PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] VerifyConditions() {
        $typeName = $this.GetType().Name
        $step = "VerifyConditions"

        Add-ConsoleLog "Start step $step of plugin $typeName"
        
        $assets = $this.Config.assets

        if ($assets -and $assets -isnot [array]) {
            throw "[GitLab] Specify the array of files to upload for a release."
        }

        if ($this.Context.CI) {
            if ($env:GITLAB_CI -eq "false") {
                throw "[GitLab] You are not running PSSemanticRelease using GitLab Pipeline"
            }

            if (-not $env:GITLAB_TOKEN -and -not $env:GL_TOKEN) {
                throw "[GitLab] No GitLab token (GITLAB_TOKEN or GL_TOKEN) found in CI environment."
            }
        }

        $token = $null

        if ($env:GITLAB_TOKEN) { $token = $env:GITLAB_TOKEN }
        if ($env:GL_TOKEN) { $token = $env:GL_TOKEN }

        Test-GitPushAccessCI -context $this.Context -token $token

        Add-ConsoleLog "Completed step $step of plugin $typeName"
    }
}