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
        $typeName = "`"$($this.PluginName)`""
        $step = "VerifyConditions"

        Add-InformationLog "Start step $step of plugin $typeName"
        
        $assets = $this.Config.assets

        if ($assets -and $assets -isnot [array]) {
            throw "[GitLab] Specify the array of files to upload for a release."
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

        Test-GitPushAccessCI -context $this.Context -token $token

        Add-SuccessLog "Completed step $step of plugin $typeName"
    }
}