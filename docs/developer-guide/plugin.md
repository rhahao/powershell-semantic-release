# How to create a Plugin

Plugins are the core of the `PSSemanticRelease` engine. They are PowerShell classes that hook into one or more steps of the release process, allowing you to extend and customize every part of the release workflow.

## The Release Pipeline

The engine executes a series of steps in a predefined order. A plugin can implement methods corresponding to these step names to participate in the release.

1.  `VerifyConditions` — Check for prerequisites (e.g., environment variables, clean git status, auth tokens).
2.  `AnalyzeCommits` — Analyze commits to determine the release type (major, minor, patch).
3.  `VerifyRelease` — Perform any final validation on the computed release metadata before `GenerateNotes`.
4.  `GenerateNotes` — Create formatted release notes from the analyzed commits.
5.  `Prepare` — Modify files, create changelogs, or package artifacts for the release.
6.  `Publish` — Publish the artifacts to repositories or registries.

---

## Plugin Architecture

### The Plugin Class

A plugin is a PowerShell class that is instantiated by the release engine. The constructor receives the plugin's name and the shared context object. The plugin is then responsible for finding its own configuration within that context.

```powershell
class MyPlugin {
    [string]$PluginName
    [PSCustomObject]$Context
    [int]$PluginIndex

    MyPlugin([string]$PluginName, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Context = $Context

        # Find this plugin's index in the project configuration for easy access.
        $this.PluginIndex = Get-PluginIndex -Plugins $this.Context.Config.Project.plugins -Name $this.PluginName

        # Call a method to set up default configuration values.
        $this.EnsureConfig()
    }

    [void] EnsureConfig() {
        # Get the default config for this plugin type.
        $configDefault = $this.Context.Config.Default.plugins | Where-Object { $_.Name -eq $this.PluginName }

        # If a specific config value is not set in the user's config, apply the default.
        if (-not $this.Context.Config.Project.plugins[$this.PluginIndex].Config.myValue) {
            $this.Context.Config.Project.plugins[$this.PluginIndex].Config.myValue = $configDefault.Config.myValue
        }
    }

    [void] VerifyConditions() {
        # Get this plugin's specific config for this step.
        $pluginConfig = $this.Context.Config.Project.plugins[$this.PluginIndex].Config
        Add-InformationLog "Start step VerifyConditions of plugin `"$($this.PluginName)`""
        # ... step logic ...
        Add-SuccessLog "Completed step VerifyConditions of plugin `"$($this.PluginName)`""
    }
}
```

### The Shared `$Context` Object

The `$Context` object is how plugins communicate with each other and with the engine. Changes made to this object by one plugin are visible to all subsequent plugins.

Key properties include:

- `Context.Config`: Contains the entire project configuration (`Project`, `Default`). A plugin must look up its own config within this object.
- `Context.CurrentVersion`: Information about the last release (`Branch`, `GitTag`, `Version`).
- `Context.NextRelease`: The heart of the release-in-progress.
  - `Context.NextRelease.Type`: (string) Set by `AnalyzeCommits` (e.g., `minor`).
  - `Context.NextRelease.Version`: (string) Set by `AnalyzeCommits` (e.g., `1.2.0`).
  - `Context.NextRelease.Notes`: (string) Set by `GenerateNotes`.
- `Context.Commits`: A list of `ConventionalCommit` objects.
- `Context.Repository`: Information about the Git repository (`Url`, `BranchCurrent`).
- `Context.DryRun`: (bool) If `$true`, plugins should avoid making any permanent changes.
- `Context.Abort`: (bool) A plugin can set this to `$true` to gracefully halt the pipeline.

---

## Development Best Practices

- **Logging**: Use the standard logging functions (`Add-InformationLog`, `Add-SuccessLog`, `Add-WarningLog`). Prefix messages with `` `"$($this.PluginName)`" `` for clarity, as shown in the examples.
- **Error Handling**: To signal a failure that should stop the pipeline, `throw` an exception. The engine will catch it and terminate the process.
- **Dry Run Mode**: Always check `$this.Context.DryRun` before performing actions with side effects (network calls, file system writes).
- **Configuration**: Use an `EnsureConfig` method, called from the constructor, to merge user-provided configuration with your plugin's defaults. This provides a robust fallback mechanism.