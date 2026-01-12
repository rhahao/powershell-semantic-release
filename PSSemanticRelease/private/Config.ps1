function Get-SemanticReleaseConfig {
    $Config = @{}

    $defaultConfigPath = "$PSScriptRoot/../config/semantic-release.json"
    $defaultConfig = Get-Content $defaultConfigPath -Raw | ConvertFrom-Json

    $userConfigFile = "semantic-release.json"
    $userConfig = @{}

    if (Test-Path $userConfigFile) {
        $userConfig = Get-Content $userConfigFile -Raw | ConvertFrom-Json
    }

    foreach ($prop in $defaultConfig.PSObject.Properties) {
        $Config[$prop.Name] = $prop.Value
    }

    foreach ($prop in $userConfig.PSObject.Properties) {
        $Config[$prop.Name] = $prop.Value
    }

    return [PSCustomObject]@{
        Default = $defaultConfig
        Config  = $Config
    }
}

function Confirm-ReleaseBranch {
    param ([PSCustomObject]$context)

    $configDefault = $context.Config.Default
    $config = $context.Config.Project
    $currentBranch = $context.Repository.BranchCurrent

    if ($null -eq $config.branches) {
        $context.Config.Project.branches = $configDefault.branches
    }

    foreach ($b in $context.Config.Project.branches) {
        if ($b -is [string] -and $b -eq $currentBranch) {
            $context.NextRelease.Channel = 'default'
            $context.NextRelease.Prerelease = $false

            return $true
        }

        if ($b.name -eq $currentBranch) {
            $context.NextRelease.Channel = $b.prerelease
            $context.NextRelease.Prerelease = $true

            return $true
        }
    }

    return $false
}