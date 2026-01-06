function New-ReleaseContext {
    return [PSCustomObject]@{
        CI = Test-CIEnvironment

        Config = Get-SemanticReleaseConfig

        Branch = $null
        Repository = ""

        Commits = [PSCustomObject]@{
            List = @()
            Formatted = $null
        }

        CurrentVersion = [PSCustomObject]@{
            Published = $null
            Branch = $null
        }

        NextRelease = [PSCustomObject]@{
            Channel = $null
            Type = $null
            Version = $null
        }

        Logger = {
            param($Message)
            Write-Host "[ps-semantic-release] $Message"
        }
    }
}