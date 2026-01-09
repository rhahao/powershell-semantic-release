function New-ReleaseContext {
    param ($DryRun)
    
    $config = Get-SemanticReleaseConfig

    $remoteUrl = Get-GitRemoteUrl
    $repoUrl = Resolve-RepositoryUrl $remoteUrl

    return [PSCustomObject]@{
        CI             = Test-CIEnvironment

        DryRun         = if ($DryRun) { $true } else { $false }

        Config         = $config.Config
        ConfigDefault  = $config.Default

        Branch         = Get-CurrentBranch
        Repository     = [PSCustomObject]@{
            RemoteUrl = $remoteUrl
            Url       = $repoUrl
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
            Channel = $null
            Type    = $null
            Version = $null
            Notes   = $null
        }
    }
}