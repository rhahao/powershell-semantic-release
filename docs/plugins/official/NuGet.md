# `@ps-semantic-release/NuGet`

A plugin for publishing PowerShell modules to NuGet-based repositories. It updates the module manifest with generated release notes and optional prerelease channel, then publishes the module using `Publish-Module`. Authentication is expected via the `NUGET_API_KEY` environment variable unless running in DryRun mode.

---

## Configuration

| Key        | Type   | Required | Default   | Description                                                                                                        |
| ---------- | ------ | -------- | --------- | ------------------------------------------------------------------------------------------------------------------ |
| path       | string | yes      | none      | Filesystem path where the module lives; plugin looks for `*.psd1` manifest under this path.                        |
| Repository | string | no       | PSGallery | Target repository name for `Publish-Module`. If omitted or empty, defaults to PSGallery.                           |
| Source     | string | no       | none      | SourceLocation URL used when registering a custom PSRepository. Required when Repository is set and not PSGallery. |

---

## Context and environment

- **Context.NextRelease.Notes** is used to build plain text release notes.
- **Context.NextRelease.Channel** is used to set `-Prerelease` on the manifest when PowerShell major version is 6 or greater and channel is not `default`.
- **Context.DryRun** disables the NUGET_API_KEY requirement and causes `Publish` to skip actual publishing.
- **Environment variable NUGET_API_KEY** must be set when not in DryRun mode.

---

## Behavior details

### `VerifyConditions`

- Ensures **path** is provided and resolves to a valid full path.
- If **Repository** is set and not **PSGallery**, requires **Source** and registers the repository with:
  ```powershell
  Register-PSRepository -Name <Repository> -SourceLocation <Source> -InstallationPolicy Trusted
  ```
- Throws clear errors for missing config or missing **NUGET_API_KEY** when required.

### `Prepare`

- Locates the module manifest using `Get-Item "<path>/*.psd1"`.
- Formats release notes from **Context.NextRelease.Notes** and injects them into the manifest via:
  ```powershell
  Update-ModuleManifest -Path <manifest> -ReleaseNotes <notes>
  ```
- Adds `-Prerelease <channel>` to `Update-ModuleManifest` when PowerShell major version is 6 or greater and channel is not `default`.

### `Publish`

- Skips publishing in DryRun mode.
- Defaults **Repository** to **PSGallery** when empty.
- Calls:
  ```powershell
  Publish-Module -Path <path> -Repository <Repository> -NuGetApiKey $env:NUGET_API_KEY
  ```

---

## Release notes formatting rules

- Markdown version headers like `# [1.14.0](link) (date)` are converted to `1.14.0 (date)`.
- Section headings like `### Bug Fixes` are converted to uppercase `BUG FIXES`.
- Bullet lines beginning with `*` are preserved with bold markers removed and commit hash link blocks removed.
- The final release notes are injected into the manifest as a plain text string.

---

## Examples

### PSGallery publish example

```json
{
  "plugins": [
    [
      "@ps-semantic-release/NuGet",
      {
        "path": "dist/PSSemanticRelease"
      }
    ]
  ]
}
```

### Private feed publish example

```json
{
  "plugins": [
    [
      "@ps-semantic-release/NuGet",
      {
        "path": "dist",
        "Repository": "MyPrivateRepo",
        "Source": "https://nuget.mycompany.local/v3/index.json"
      }
    ]
  ]
}
```
