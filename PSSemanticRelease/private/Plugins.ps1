function Update-PluginsList {
    param ([PSCustomObject]$context)

    $default = $context.Config.Default.plugins
    $context.Config.Default.plugins = Format-PluginsList $default

    $projectPlugins = $context.Config.Project.plugins

    if ($projectPlugins -isnot [array] -or $projectPlugins.Count -eq 0) {
        throw "No plugins configured. Either remove the plugins section from the config or add at least one plugin."
    }

    $context.Config.Project.plugins = Format-PluginsList $projectPlugins
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

    $plugins = $context.Config.Project.plugins

    $finalPlugins = @()

    foreach ($plugin in $plugins) {
        $findPlugin = Get-Item -Path "$PSScriptRoot/../plugins/$($plugin.Name).ps1" -ErrorAction SilentlyContinue

        if (-not $findPlugin) {
            throw "Plugin $($plugin.Name) not found."
        }

        $className = $plugin.Name
        $instance = New-Object -TypeName ([Ref]$className).Value -ArgumentList $plugin.Config, $Context

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

function Get-PluginIndex {
    param(
        [array]$Plugins,
        [string]$Name
    )

    $index = -1
    for ($i = 0; $i -lt $Plugins.Count; $i++) {
        if ($Plugins[$i].Name -eq $Name) {
            $index = $i
            break
        }
    }

    return $index
}
