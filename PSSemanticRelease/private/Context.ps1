function New-ReleaseContext {
    param ($DryRun)
    
    $config = Get-SemanticReleaseConfig

    $remoteUrl = Get-GitRemoteUrl
    $repoUrl = Resolve-RepositoryUrl $remoteUrl

    return [PSCustomObject]@{
        Abort          = $false

        EnvCI          = Get-CIContext

        DryRun         = if ($DryRun) { $true } else { $false }

        Config         = [PSCustomObject]@{
            Default = $config.Default
            Project = $config.Config
        }
        
        Repository     = [PSCustomObject]@{
            BranchDefault   = Get-BranchDefault
            BranchCurrent   = $null
            Url             = $repoUrl
            OriginRemoteUrl = Get-GitOriginRemoteUrl
            RemoteUrl       = Get-GitRemoteUrl
        }

        Commits        = [PSCustomObject]@{
            List      = @()
            Formatted = $null
        }

        CurrentVersion = [PSCustomObject]@{
            Published = $null
            Branch    = $null
        }

        NextRelease    = [PSCustomObject]@{
            Channel    = $null
            Prerelease = $false
            Type       = $null
            Version    = $null
            Notes      = $null
        }
    }
}