# Plugins

Each release step in **PSSemanticRelease** is implemented by configurable plugins. This allows support for different commit message formats, release note generators, versioning strategies, and publishing platforms.

A plugin is a **PowerShell module class** that can implement one or more of the following release steps.

## Release Steps

A **PSSemanticRelease** run executes the following steps in order:

| Step               | Description                                                                                                        |
| ------------------ | ------------------------------------------------------------------------------------------------------------------ |
| `VerifyConditions` | Verify that the environment and configuration are valid (CI context, credentials, clean working tree, etc.).       |
| `AnalyzeCommits`   | Determine the type of the next release (`major`, `minor`, `patch`) based on commit history.                        |
| `VerifyRelease`    | Perform additional validation on the computed release (version, prerelease channel, etc.).                         |
| `GenerateNotes`    | Generate release notes from commit history.                                                                        |
| `Prepare`          | Prepare the release by updating files (CHANGELOG, module manifest), running scripts, and creating commits or tags. |
| `Publish`          | Publish the release (Git tag push, GitHub/GitLab release, NuGet publishing, etc.).                                 |

Release steps always run in this order. For each step, **all plugins that implement that step are executed.**

> [!IMPORTANT]
> If multiple plugins implement the same step, they are executed sequentially.

## Required Plugin

At least **one plugin implementing `AnalyzeCommits` is required.** Without it, **PSSemanticRelease** cannot determine the next version.

By default, this role is fulfilled by:

- `@ps-semantic-release/CommitAnalyzer`

## Default Plugins

Commonly used plugins include:

- `@ps-semantic-release/CommitAnalyzer`
- `@ps-semantic-release/ReleaseNotesGenerator`
- `@ps-semantic-release/Changelog`
- `@ps-semantic-release/Git`
- `@ps-semantic-release/GitHub`
- `@ps-semantic-release/GitLab`
- `@ps-semantic-release/NuGet`
- `@ps-semantic-release/Exec`

## Plugin Declaration and Execution Order

Plugins are configured in `semantic-release.json` using the `plugins` array.

```json
{
  "plugins": [
    "@ps-semantic-release/CommitAnalyzer",
    "@ps-semantic-release/ReleaseNotesGenerator",
    "@ps-semantic-release/Git"
  ]
}
```

> [!WARNING]
> When the plugins option is defined, it fully overrides the default plugin list.

### Execution Order Rules

- **Release steps determine the primary order** (`VerifyConditions → AnalyzeCommits → GenerateNotes → Prepare → Publish`)
- **Within each step,** plugins are executed **in the order they appear in the plugins array**

### Example Execution Flow

```json
{
  "plugins": [
    "@ps-semantic-release/CommitAnalyzer",
    "@ps-semantic-release/ReleaseNotesGenerator",
    "@ps-semantic-release/NuGet",
    "@ps-semantic-release/Git"
  ]
}
```

This configuration results in:

- **VerifyConditions**
  - `@ps-semantic-release/CommitAnalyzer`
  - `@ps-semantic-release/NuGet`
  - `@ps-semantic-release/Git`
- **AnalyzeCommits**
  - `@ps-semantic-release/CommitAnalyzer`
- **GenerateNotes**
  - `@ps-semantic-release/ReleaseNotesGenerator`
- **Prepare**
  - `@ps-semantic-release/NuGet`
  - `@ps-semantic-release/Git`
- **Publish**
  - `@ps-semantic-release/NuGet`
  - `@ps-semantic-release/Git`

## Plugin Options Configuration

Plugins can be configured in two ways:

### Per-Plugin Configuration

To configure a specific plugin, wrap it in an array with its options object:

```json
{
  "plugins": [
    [
      "@ps-semantic-release/Exec",
      {
        "preparePsScript": "create-dist.ps1 {NextRelease.Version}"
      }
    ]
  ]
}
```

These options are passed **only to that plugin.**

### Global Configuration

Some configuration options can be defined at the root level and are available to all plugins via the release context.

Example:

```json
{
  "unifyTag": true,
  "plugins": [
    "@ps-semantic-release/CommitAnalyzer",
    "@ps-semantic-release/ReleaseNotesGenerator"
  ]
}
```

In this case:

- All plugins receive `unifyTag` through the shared release context
- Plugins that do not use the option simply ignore it

## Notes

- Plugins are loaded dynamically at runtime.
- A plugin may implement **any subset** of release steps.
- `DryRun` mode is respected by all built-in plugins.
- The execution model closely mirrors the official [_semantic‑release_](https://semantic-release.gitbook.io/semantic-release/#release-steps) pipeline, adapted for PowerShell and CI environments.
