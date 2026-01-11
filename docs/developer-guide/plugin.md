# Creating a Plugin

A **PSSemanticRelease** plugin is a PowerShell class that implements one or more lifecycle steps. Each step receives:

- `$Config` — the plugin-specific configuration from `semantic-release.json`.
- `$Context` — the runtime context, including commit info, release info, environment variables, and dry-run flag.

You can implement only the lifecycles your plugin needs. Typical lifecycles include:

- `VerifyConditions` — check that configuration and environment variables are valid.
- `AnalyzeCommits` — analyze commits to determine the next release type.
- `VerifyRelease` — validate the release metadata.
- `GenerateNotes` — create formatted release notes.
- `Prepare` — update changelogs, manifests, or prepare artifacts.
- `Publish` — publish artifacts to repositories or registries.

## Plugin Class Structure

```powershell
class MyPlugin {
    [string]$PluginName
    [PSCustomObject]$Config
    [PSCustomObject]$Context

    MyPlugin([string]$PluginName, [PSCustomObject]$Config, [PSCustomObject]$Context) {
        $this.PluginName = $PluginName
        $this.Config = $Config
        $this.Context = $Context
    }

    [void] SomeHelperFunction() {
        # create your helper inside the class
    }

    [void] VerifyConditions() {
        # Check configuration, environment variables, or repository setup
        if (-not $this.Config.Path) {
            throw "[$($this.PluginName)] Config 'Path' is required"
        }
    }

    [void] Prepare() {
        # Prepare artifacts, update changelogs or manifests
        $this.Context.NextRelease.Notes = "Release notes here"
    }

    [void] Publish() {
        # Publish artifacts (e.g., NuGet/PSGallery)
        if (-not $this.Context.DryRun) {
            Write-Host "Publishing module..."
        }
    }
}
```

## Key Points

- **Constructor** — receives plugin name, config, and context.
- **Lifecycle methods** — implement only the steps needed (`VerifyConditions`, `AnalyzeCommits`, `Prepare`, `Publish`, etc.).
- **DryRun support** — check `$this.Context.DryRun` to skip actions safely.
- **Logging** — use `Add-InformationLog`, `Add-SuccessLog`, `Add-WarningLog` for consistent output.
- **Configuration validation** — always validate required config and environment variables in `VerifyConditions`.
- **Formatting release notes** — can be done in a helper method inside the plugin (e.g., `FormatReleaseNotes()`).

## Example Plugin Flow (NuGet)

- `VerifyConditions`
  Checks that `NUGET_API_KEY` is set and the module path exists.
- `Prepare`
  Updates module manifest, formats release notes, adds pre-release info if applicable.
- `Publish`
  Pushes the module to PSGallery or another NuGet repository if `DryRun` is false.

## Using Context

`$Context` provides runtime information to the plugin:

- `DryRun` — Boolean, true if in dry-run mode.
- `NextRelease` — Contains `Version`, `Channel`, `Notes`, etc.
- `Commits` — List of commits since last release.

## Logging

Use provided logging functions to output consistent messages:

- `Add-InformationLog` "Some info message"
- `Add-WarningLog` "Some warning"
- `Add-SuccessLog` "Step completed successfully"

This ensures messages are standardized in PSSemanticRelease output.
