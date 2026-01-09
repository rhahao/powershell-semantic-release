function Update-PluginsList {
    param ([PSCustomObject]$context)

    $default = $context.ConfigDefault.plugins
    $context.ConfigDefault.plugins = Format-PluginsList $default

    $userPlugins = $context.Config.plugins

    if ($userPlugins -isnot [array] -or $userPlugins.Count -eq 0) {
        throw "No plugins configured. Either remove the plugins section from the config or add at least one plugin."
    }

    $context.Config.plugins = Format-PluginsList $userPlugins
}

function Format-PluginsList {
    param([PSCustomObject]$plugins)

    $finalPlugins = @()

    foreach ($plugin in $plugins) {
        $pluginItem = @{
            Name   = ""
            Config = @{}
        }

        if ($plugin -is [string]) {
            $pluginItem.Name = $plugin
        }
        else {
            $pluginItem.Name = $plugin[0]
            $pluginItem.Config = $plugin[1]
        }

        $finalPlugins += $pluginItem
    }

    return $finalPlugins
}

function Get-SemanticReleasePlugins {
    param([PSCustomObject]$Context)

    $plugins = $context.Config.plugins

    $finalPlugins = @()

    foreach ($plugin in $plugins) {
        $findPlugin = Get-Item -Path "$PSScriptRoot/../plugins/$($plugin.Name).ps1" -ErrorAction SilentlyContinue

        if (-not $findPlugin) {
            throw "Plugin $($plugin.Name) not found."
        }

        $className = $plugin.Name
        $instance = New-Object -TypeName ([Ref]$className).Value -ArgumentList @($plugin.Config, $Context)

        $finalPlugins += $instance
    }

    return $finalPlugins
}

function Test-PluginStepExist {
    param(
        [object]$Plugin,
        [string]$Step
    )

    $method = $Plugin | Get-Member -Name $Step -MemberType Method -ErrorAction SilentlyContinue
    return $null -ne $method
}
