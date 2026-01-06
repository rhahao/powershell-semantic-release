function New-ReleaseContext {
    return [PSCustomObject]@{
        Env = [PSCustomObject]@{
            IsCI = Test-CIEnvironment
        }

        Config = Get-SemanticReleaseConfig

        Branch = $null
        Repository = $null

        Commits = [PSCustomObject]@{
            List = @()
            Formatted = $null
        }

        CurrentVersion = [PSCustomObject]@{
            Published = $null
            Branch = $null
        }

        NextVersion = [PSCustomObject]@{
            Channel = $null
            Type = $null
            Value = $null
        }

        Logger = {
            param($Message)
            Write-Host "[ps-semantic-release] $Message"
        }
    }
}