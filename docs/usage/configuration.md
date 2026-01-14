# Configuration

**PSSemanticRelease** is configured via a file named `semantic-release.json` in the root of your project (alongside your repository).

This file controls:

- What branches can trigger releases
- How versions are determined
- What actions are taken at each phase
- Plugin behavior and options

## Configuration File Format

The config file is a JSON object with the following top‑level keys:

| Field      | Type    | Description                                        |
| ---------- | ------- | -------------------------------------------------- |
| `branches` | array   | Release branches with optional prerelease settings |
| `unifyTag` | boolean | Shares version tags across branches                |
| `plugins`  | array   | List of plugins and their configs                  |

### `branches`

The branches setting defines which branches can trigger releases and how prereleases are handled. Your default configuration supports:

```json
"branches": [
  "main",
  { "name": "beta", "prerelease": "beta" },
  { "name": "alpha", "prerelease": "alpha" }
]
```

- `"main"` → production releases
- `"beta"` → beta prerelease versions (1.0.0-beta.1)
- `"alpha"` → alpha prerelease versions (1.0.0-alpha.1)

> Prereleases help you publish early builds while still keeping the main versioning line clean.

### `unifyTag`

- When `unifyTag` is **true**, all branches share the same Git tags.
- When **false**, each branch generates tags independently.

```json
"unifyTag": true
```

- Use `unifyTag: true` when you want a **single version history** across branches (main/beta/alpha).
- Use `false` if you want isolated tagging per branch.

### `plugins`

Plugins define the **steps of a release.** Each plugin can implement one or more lifecycle steps:

```txt
VerifyConditions → AnalyzeCommits → VerifyRelease → GenerateNotes → Prepare → Publish
```

#### Plugin format

A plugin can be:

- A **string** → uses default behavior
- An **array** → `[pluginName, pluginConfig]`

Example:

```json
["@ps-semantic-release/Git"]
```

OR with custom options:

```json
[
  "@ps-semantic-release/Exec",
  { "preparePsScript": "create-dist.ps1 {NextRelease.Version}" }
]
```

#### Built‑In Plugins

Here are the core plugins available by default:

| Plugin                                       | Purpose                                            |
| -------------------------------------------- | -------------------------------------------------- |
| `@ps-semantic-release/CommitAnalyzer`        | Analyzes commit messages to determine release type |
| `@ps-semantic-release/ReleaseNotesGenerator` | Generates release notes from commits               |
| `@ps-semantic-release/Changelog`             | Updates or creates `CHANGELOG.md`                  |
| `@ps-semantic-release/Git`                   | Commits, tags, and pushes to Git                   |
| `@ps-semantic-release/GitHub`                | Creates GitHub releases                            |
| `@ps-semantic-release/GitLab`                | Creates GitLab releases                            |
| `@ps-semantic-release/NuGet`                 | Publishes PowerShell modules                       |
| `@ps-semantic-release/Exec`                  | Runs custom scripts at lifecycle stages            |

## Example Configuration

This example shows how you might configure a workflow for a PowerShell module:

```json
{
  "plugins": [
    "@ps-semantic-release/CommitAnalyzer",
    "@ps-semantic-release/ReleaseNotesGenerator",
    "@ps-semantic-release/Changelog",
    "@ps-semantic-release/Git",
    [
      "@ps-semantic-release/Exec",
      {
        "preparePsScript": "create-dist.ps1 -NoProfile -ExecutionPolicy Bypass {NextRelease.Version}"
      }
    ],
    ["@ps-semantic-release/NuGet", { "path": "dist/PSSemanticRelease" }],
    "@ps-semantic-release/GitHub"
  ],
  "unifyTag": true
}
```

This configuration:

- Uses a unified tag history
- Analyzes commits for version bumps
- Generates release notes and updates changelog
- Commits and pushes using Git
- Runs a custom “prepare” script
- Publishes to NuGet/PSGallery
- Creates a GitHub release
