function New-ReleaseContext {
    param ($DryRun)

    return [PSCustomObject]@{
        CI             = Test-CIEnvironment

        DryRun         = if ($DryRun) { $true } else { $false }

        Config         = Get-SemanticReleaseConfig

        Branch         = $null
        Repository     = [PSCustomObject]@{
            RemoteUrl = $null
            Url       = $null
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