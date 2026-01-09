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