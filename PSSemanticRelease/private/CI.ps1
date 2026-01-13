function Get-CIContext {
    try {
        $ctx = @{
            IsCI         = $false
            Provider     = $null
            Branch       = $null
            Tag          = $null
            Commit       = $null
            IsPR         = $false
            PRNumber     = $null
            PRBranch     = $null
            TargetBranch = $null
        }

        # -----------------------
        # GitLab CI
        # -----------------------
        if ($env:GITLAB_CI) {
            $ctx.IsCI = $true
            $ctx.Provider = 'gitlab'
            $ctx.Branch = $env:CI_COMMIT_BRANCH
            $ctx.Tag = $env:CI_COMMIT_TAG
            $ctx.Commit = $env:CI_COMMIT_SHA
            $ctx.IsPR = [bool]$env:CI_MERGE_REQUEST_IID
            $ctx.PRNumber = $env:CI_MERGE_REQUEST_IID
            $ctx.PRBranch = $env:CI_MERGE_REQUEST_SOURCE_BRANCH_NAME
            $ctx.TargetBranch = $env:CI_MERGE_REQUEST_TARGET_BRANCH_NAME
            $ctx.Token = if ($env:GL_TOKEN) { $env:GL_TOKEN } else { $env:GITLAB_TOKEN }
        }

        # -----------------------
        # GitHub Actions
        # -----------------------
        elseif ($env:GITHUB_ACTIONS) {
            $ctx.IsCI = $true
            $ctx.Provider = 'github'
            $ctx.Commit = $env:GITHUB_SHA
            $ctx.Branch = $env:GITHUB_REF_NAME
            $ctx.IsPR = $env:GITHUB_EVENT_NAME -eq 'pull_request'
            $ctx.Token = if ($env:GH_TOKEN) { $env:GH_TOKEN } else { $env:GITHUB_TOKEN }
        }

        # -----------------------
        # Local fallback
        # -----------------------
        if (-not $ctx.IsCI) {
            $ctx.Provider = 'local'
            $ctx.Commit = git rev-parse HEAD 2>$null
            $branch = git rev-parse --abbrev-ref HEAD 2>$null
            if ($branch -ne 'HEAD') {
                $ctx.Branch = $branch
            }
        }

        return [PSCustomObject]$ctx
    }
    catch {
        Add-FatalLog $_
    }
}
